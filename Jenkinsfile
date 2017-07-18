properties properties: [
    [
        $class: 'BuildDiscarderProperty',
        strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '30']
    ]
]

node('ecs docker') {

    def contributors = null
    def Utils
    def buildLabel
    def gitLabel
    def stageTag
    currentBuild.result = "SUCCESS"

    stage ('Checkout Source') {
        deleteDir()
        checkout scm
        getUtils()
        // load pipeline utility functions
        Utils = load "utils/Utils.groovy"
        buildLabel = Utils.&getBuildLabel()
        gitLabel = Utils.&getGitDescribe()
        stageTag = Utils.&getDockerStageTag()
    }

    stage ('Create Change Logs') {
        sshagent(['38bf8b09-9e52-421a-a8ed-5280fcb921af']) {
            try {
                Utils.&copyArtifactWhenAvailable("Cogosense/Postfix/${env.BRANCH_NAME}", 'SCM/CHANGELOG', 1, 0)
            }
            catch(err) {}

            dir("./SCM") {
                sh '../utils/scmBuildDate > TIMESTAMP'
                writeFile file: "TAG", text: buildLabel
                writeFile file: "URL", text: env.BUILD_URL
                writeFile file: "BRANCH", text: env.BRANCH_NAME
                sh '../utils/scmBuildContributors > CONTRIBUTORS'
                sh '../utils/scmBuildOnHookEmail > ONHOOK_EMAIL'
                sh "../utils/scmUpdateChangeLog -t ${buildLabel} -o CHANGELOG"
                sh '../utils/scmTagLastBuild'
            }
        }
    }

    try {
        contributors = readFile './SCM/ONHOOK_EMAIL'

        stage ('Notify Build Started') {
            Utils.&sendOnHookEmail(contributors)
        }

        def app
        stage ('Build Docker') {
            dir("./src") {
                app = docker.build('postfix')
            }
        }

        stage ('Push Docker') {
            docker.withRegistry('https://053262612181.dkr.ecr.us-west-2.amazonaws.com', 'ecr:us-west-2:bae55279-e86a-4337-b246-ba0b28902a91') {
                app.push(gitLabel)
                app.push(stageTag)
            }
        }

        stage ('Archive SCM') {
            step([$class: 'ArtifactArchiver',
                artifacts: 'SCM/**',
                fingerprint: true,
                onlyIfSuccessful: true])
        }
    }
    catch(err) {
        currentBuild.result = "FAILURE"
        Utils.&sendFailureEmail(contributors, err)
        throw err
    }

    stage ('Notify Build Completion') {
        Utils.&sendOffHookEmail(contributors)
    }
}

def getUtils() {
    // Load the SCM util scripts
    checkout([$class: 'GitSCM',
        branches: [[name: "*/${env.BRANCH_NAME}"]],
        doGenerateSubmoduleConfigurations: false,
        extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'utils']],
        submoduleCfg: [],
        userRemoteConfigs: [[url: 'git@github.com:Cogosense/JenkinsUtils.git', credentialsId: '38bf8b09-9e52-421a-a8ed-5280fcb921af']]])
}
