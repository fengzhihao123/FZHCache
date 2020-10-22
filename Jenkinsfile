node {
    stage('SCM') {
        git([url: 'https://github.com/fengzhihao123/FZHCache.git'])
    }
    stage('SonarQube analysis') {
        def sonarqubeScannerHome = tool name: 'SonarQube Scanner'

        withSonarQubeEnv('SonarQube') {
            sh "${sonarqubeScannerHome}/bin/sonar-scanner"
        }
    }
}