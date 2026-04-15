# Dev Spaces Demo for real world applications

This Dev Spaces Demo demonstrates how to develop an application which has different dependencies while developing it locally. 
Of course - as application developers - we would like to have isolated microservices which are designed to be developed without any related infrastructure. 
The goal is to write unit tests, integration tests and e2e tests so you don't need any additional components deployed to just develop the simple microservice on your local machine. 

But in reality we see a lot of legacy applications with dependencies to different components. And often it's not possible to test one component locally without having other components available. This is the reason why I created this demo to show that it's possible to solve this scenario in OpenShift Dev Spaces as well. 

So you are able to develop your application fully containerized in a standardized and secure environment. 
And this is a very good first step to modernize the application and decouple components for the future. 

## Demo Application's Architecture

This is the entry point for a demo with several repositories involved: 
* [Root Repo / This Repo](https://github.com/marcoklaassen/devspaces-contract-demo-devspaces)
 * [Infrastructure (Database, Kafka)](https://github.com/marcoklaassen/devspaces-contract-demo-infrastructure)
 * [Backend Application (Contract Backend)](https://github.com/marcoklaassen/devspaces-contract-demo-backend)
 * [External API (Customer Backend)](https://github.com/marcoklaassen/devspaces-contract-demo-customer-api)


```
 external component outside        │     The component              │       Components I want  
 my devspaces namespace                I want to work on                    to start during    
                                   │                                │       local development  
─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
                                   │                                │                          
                                                                                               
   ┌────────────────┐              │                                │                          
   │Customer Backend│                               persist new contract    ┌─────────────────┐
   │ -external API- │              │          ┌─────────────────────│───────┤Contract Database│
   └───────┬────────┘                         │                             └─────────────────┘
           │                       │          │                     │                          
           │                                  │                                                
           │   ask if customer     │ ┌────────┴───────┐             │                          
           └─────────────────────────┤Contract Backend│                                        
               already exists      │ └────────┬───────┘             │                          
                                              │                                                
                                   │          │                     │                          
                                              │                                                
                                   │          │                     │                          
                                              │                            ┌────────────────┐  
                                   │          │                     │      │Kafka           │  
                                              └────────────────────────────┤                │  
                                   │             consume new        │      │Topic: Contracts│  
                                                 contract event            └───────┬────────┘  
                                   │                                │              │           
                                                                                   │           
                                   │                                │              │produce    
                                                                                   │new        
                                   │                                │              │contract   
                                                                                   │           
                                   │                                │     ┌────────┴────────┐  
                                                                          │Customer Frontend│  
                                   │                                │     └─────────────────┘  
```

## DevSpaces Demo Parts 

* custom Universal Developer Image 
 * update Java Version
 * install quarkus cli
* Devfile integration
* Default Extensions incl. configuration of database connection

## Prerequisites

* OpenShift DevSpaces Operator
* OpenShift Pipelines Operator
* Streams for Apache Kafka Operator

## Configuration of Dev Spaces

### Enable Public Extension Registry

`oc edit checluster devspaces -n <devspaces_namespace>` (usually openshift-operators)

Update the openVSXURL: Locate the spec.components.pluginRegistry section and set the openVSXURL field to the public registry URL.

```
spec:
  components:
    pluginRegistry:
      # ... other settings ...
      openVSXURL: 'https://open-vsx.org'  # <-- Change this

```

### Configure Git & VSCode Editor

```
oc apply -f gitconfig-configmap.yaml
oc apply -f vscode-editor-configurations.yaml 

```

### Configure Github Oauth

```
# https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.27/html/administration_guide/assembly_configuring-oauth-for-git-providers_administration_guide#proc_setting-up-the-github-oauth-app_administration_guide
oc apply -f github-secret.yaml -n openshift-operators
```

### Configure OpenShift Pipelines 

To access the UDI base image the pipeline service account must have access to registry.redhat.io. 
And to push the image to the quay.io repository the service account must also have access to the repository. 

```
# usually done in the <username>-devspaces namespace
oc create secret generic container-registry-credentials --from-file=.dockerconfigjson=<path-to-your-dockerconfig.json> --type=kubernetes.io/dockerconfigjson
oc secret link pipeline container-registry-credentials                                                   
oc secret link pipeline container-registry-credentials --for pull
```

## Demo

### Start the Developer Environment 

Open the Dev Spaces Dashboard and `Create & Open` the GitHub Repo:

![start-dev-end](img/start-developer-env.png)

The Devfile will be applied and your IDE will be prepared for you. 

### Install the application's dependencies

To open the application's dependencies execute the prepared command: `Run Task -> Devfile -> 0. [Infrastructure] ...`

![alt text](img/open-command.png)

![alt text](img/devfile-command.png)

![alt text](img/helm-result.png)

You can also check if the database (which is provisioned by the infrastructure helm chart) is available. The `vscode-editor-configurations.yaml` already installed and configured the SQLTools for you: 

![alt text](img/sql-tools.png)

The second check you should to is about the kafka infrastructure. Open a new terminal in your IDE and check the deployment: 

Containers are running ☑️
```
contract-backend (main) $ oc get pods
NAME                                         READY   STATUS    RESTARTS   AGE
kafka-broker-0                               1/1     Running   0          5m9s
kafka-broker-1                               1/1     Running   0          5m9s
kafka-broker-2                               1/1     Running   0          5m9s
kafka-controller-3                           1/1     Running   0          5m8s
kafka-controller-4                           1/1     Running   0          5m8s
kafka-controller-5                           1/1     Running   0          5m8s
kafka-entity-operator-686c48986c-pqcrq       2/2     Running   0          2m23s
postgresql-7cfd947f67-fcwkv                  1/1     Running   0          5m13s
workspace1ea012ac59bf4f86-79dd7c5485-725vv   2/2     Running   0          17m
```

Kafka Cluster ready ☑️
```
contract-backend (main) $ oc get kafka
NAME    READY   METADATA STATE   WARNINGS
kafka   True    KRaft            
```

Kafka Topic ready ☑️
```
contract-backend (main) $ oc get kafkatopics.kafka.strimzi.io 
NAME       CLUSTER   PARTITIONS   REPLICATION FACTOR   READY
contract   kafka     1            1                    True
```


Kafka User ready ☑️
```
contract-backend (main) $ oc get kafkausers.kafka.strimzi.io 
NAME              CLUSTER   AUTHENTICATION   AUTHORIZATION   READY
kafka-developer   kafka     scram-sha-512    simple          True
```