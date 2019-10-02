#!groovy

@Library('pipeline-library') _

def img

node {
    stage('build') {
        checkout(scm)
        img = buildApp(name: 'hypothesis/proxy-server')
    }

    stage('test') {
        try {
            testApp(image: img, runArgs: "-p 9081:80 -e VIA_URL=http://localhost:9080 -e H_EMBED_URL=http://localhost:5000/embed.js") {
            }
        } finally {
        }
    }

    onlyOnMaster {
        stage('release') {
            releaseApp(image: img)
        }
    }
}

onlyOnMaster {
    milestone()
    stage('qa deploy') {
        deployApp(image: img, app: 'proxy-server', env: 'qa')
    }
    
    milestone()
    stage('prod deploy') {
        input(message: "Deploy to prod?")
        milestone()
        deployApp(image: img, app: 'proxy-server', env: 'prod')
    }
}

def containerPort(container, port) {
    return sh(
        script: "docker port ${container.id} ${port} | cut -d: -f2",
        returnStdout: true
    ).trim()
}
