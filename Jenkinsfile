node {
  stage('SCM') {
    git 'https://github.com/fengzhihao123/FZHCache.git'
  }
  
  stage('Begin') {
    echo 'begin sonarqube analysis'
  }
  
  stage('SonarQube analysis') {
    def scannerHome = tool 'SonarScanner 4.5.0';
    withSonarQubeEnv('MyScanner') { // If you have configured more than one global server connection, you can specify its name
      sh "${scannerHome}/bin/sonar-scanner"
    }
  }
}
