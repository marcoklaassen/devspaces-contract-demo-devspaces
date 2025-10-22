# Dev Spaces Demo for real world applications

This Dev Spaces Demo demonstrates how to develop an application which has different dependencies while developing it locally. 
Of course - as application developers - we would like to have isolated microservices which are designed to be developed without any related infrastructure. 
The goal is to write unit tests, integration tests and e2e tests so you don't need any additional components deployed to just develop the simple microservice on your local machine. 

But in reality we see a lot of legacy applications with dependencies to different components. And often it's not possible to test one component locally without having other components available. This is the reason why I created this demo to show that it's possible to solve this scenario in OpenShift Dev Spaces as well. 

So you are able to develop your application fully containerized in a standardized and secure environment. 
And this is a very good first step to modernize the application and decouple components for the future. 

## Demo Application's Architecture

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

## Configure OpenShift Pipelines 

To access the UDI base image the pipeline service account must have access to registry.redhat.io. 
And to push the image to the quay.io repository the service account must also have access to the repository. 

```
oc create secret generic container-registry-credentials --from-file=.dockerconfigjson=<path-to-your-dockerconfig.json> --type=kubernetes.io/dockerconfigjson
oc secret link pipeline container-registry-credentials                                                   
oc secret link pipeline container-registry-credentials --for pull
```

## Enable Public Extension Registry

`oc edit checluster devspaces -n <devspaces_namespace>`

Update the openVSXURL: Locate the spec.components.pluginRegistry section and set the openVSXURL field to the public registry URL.

```
spec:
  components:
    pluginRegistry:
      # ... other settings ...
      openVSXURL: 'https://open-vsx.org'  # <-- Change this
```