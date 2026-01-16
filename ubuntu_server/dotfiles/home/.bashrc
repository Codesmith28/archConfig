# At the VERY TOP
[[ $- != *i* ]] && return

echo "Hello Codesmith"

source ~/.profile

# Added by setup-java-toolchains.sh
export JAVA_11_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

# Added by setup-java-toolchains.sh
export JAVA_21_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

export KUBECONFIG='$HOME/.kube/config'
