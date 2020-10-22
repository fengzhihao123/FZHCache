node {
  stage('SCM') {
    git 'https://github.com/fengzhihao123/FZHCache.git'
  }
  stage('SonarQube analysis') {
    def scannerHome = tool 'SonarQube_Scanner';
    withSonarQubeEnv('MySonar') { // If you have configured more than one global server connection, you can specify its name
      sh "${scannerHome}/bin/sonar-scanner"
    }
  }
}
