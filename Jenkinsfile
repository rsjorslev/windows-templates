pipeline {
  agent any
  stages {
    stage('Pre-Start') {
      steps {
        sh 'printenv'
        sh '${PACKER}/packer -v'
        sh 'printenv'
      }
    }
    stage('Validate') {
      steps {
        sh '${PACKER}/packer validate vmware-win2016.json'
      }
    }
    stage('Build') {
      steps {
        sh '${PACKER}/packer build vmware-win2016.json'
      }
    }
  }
  environment {
    PACKER = tool('packer_v102')
    ESXI_CREDS = credentials('esx-tstdmn')
    ESXI_HOST = 'esx01.tstdmn.dk'
    DVPORTGROUP_ID = 'dvportgroup-67'
    SWITCH_ID = '50 18 a9 9e 92 d0 de cd-1a 88 ce bc 53 3c 03 d1'
    DATASTORE = 'ssd-raid0-001'
    PACKER_LOG = '1'
  }
}
