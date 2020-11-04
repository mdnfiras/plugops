pipeline {
    agent any
    environment {
        GIT_LATEST_COMMIT_EDITOR= sh(
            returnStdout:true,
            script: 'git show -s --pretty=%cn '
        ).trim()
        GIT_LATEST_COMMIT_AUTHOR= sh(
            returnStdout:true,
            script: 'git show -s --pretty=%an '
        ).trim()
        GIT_LATEST_COMMIT_MESSAGE= sh(
            returnStdout:true,
            script: 'git log -1 --pretty=%B | head -1'
        ).trim()
        GIT_STAT= sh(
            returnStdout: true,
            script: "git diff --stat ${get_previous_commit_id().trim()}"
        ).trim()
        GIT_SHORT_STAT= sh(
            returnStdout: true,
            script: "git diff --shortstat ${get_previous_commit_id().trim()}"
        ).trim()
        GIT_COMPARE_URL = "${return_github_url().trim()}/compare/${env.GIT_COMMIT.trim()}..${get_previous_commit_id().trim()}"
        GIT_SSH_URL = sh(
            returnStdout: true,
            script: "git config --get remote.origin.url | sed 's/https:\\/\\/github.com\\//git@github.com:/g'"
        )
        GIT_CURRENT_BRANCH = sh(
            returnStdout: true,
            script: "git rev-parse --abbrev-ref HEAD"
        )
	}

    parameters {
        string(name: 'SLACK_CHANNEL', defaultValue:'#firas', description: 'slack channel to notify')
    }

    stages {
        stage ('test') {
            steps {
                sh 'ls -l'
            }
        }
    }
    
    post {
        success {
            slackSend color: 'good',
            message: """
                Build ${env.BUILD_NUMBER} completed successfully for ${env.JOB_NAME}.
                changes: <${env.RUN_CHANGES_DISPLAY_URL}|here>
                Latest Commit: <${return_github_url().trim()}/commit/${env.GIT_COMMIT.trim()}|${env.GIT_LATEST_COMMIT_MESSAGE}>
                with id: ${env.GIT_COMMIT}
                ${env.GIT_SHORT_STAT}
                ${env.GIT_LATEST_COMMIT_AUTHOR} authored and ${env.GIT_LATEST_COMMIT_EDITOR} committed
                <${env.GIT_COMPARE_URL}|Compare against previous build>
                More Details <${env.BUILD_URL}|here>
			    """,
			channel: "${params.SLACK_CHANNEL}"
        }
        failure {
            slackSend color: 'danger',
	    	message: """
                Build ${env.BUILD_NUMBER} Failed for ${env.JOB_NAME}. 
                changes: <${env.RUN_CHANGES_DISPLAY_URL}|here>
                Latest commit: <${return_github_url().trim()}/commit/${env.GIT_COMMIT.trim()}|${env.GIT_LATEST_COMMIT_MESSAGE}>
                ${env.GIT_SHORT_STAT}
                ${env.GIT_LATEST_COMMIT_AUTHOR} authored and ${env.GIT_LATEST_COMMIT_EDITOR} committed
                <${env.GIT_COMPARE_URL}|Compare against previous build>
                More Details<${env.BUILD_URL}|here>
			    """,
			channel:"${params.SLACK_CHANNEL}"
        }
    }
}

def return_github_url() {
	def url = sh(script: 'echo "$GIT_URL" | sed -e "s/\\.git[^.]*$//"', returnStdout: true)
	return url.trim()
}

def get_previous_commit_id() {
    def commit_id = sh(returnStdout: true,
    script: '''
    commitsCount=$(git rev-list --count HEAD )
    if [ $commitsCount -lt 2 ]; then
        commitId=4b825dc642cb6eb9a060e54bf8d69288fbee4904
    else
        prevCommit=$(git log -n 2 --pretty=%H | tail -1 )
        if [ -z "$GIT_PREVIOUS_SUCCESSFUL_COMMIT" ]; then
            commitId=$prevCommit
        else
            if res=$(git log -n 1 --pretty=%H $GIT_PREVIOUS_SUCCESSFUL_COMMIT ) ; then
                commitId=$GIT_PREVIOUS_SUCCESSFUL_COMMIT
            else
                commitId=$prevCommit
            fi
        fi
    fi
    echo $commitId
    ''')
    return commit_id;
}