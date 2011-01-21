##########################################################################
#    multivariateClassificationUtils.R  CONTAINS ALL USEFUL FUNCTIONS    #
#    FOR THE MULTIVARIATE CLASSIFICATION                                 #
##########################################################################


library(FactoMineR)
library(cluster)
library(graphics)
library(stats)
library(SOAR)
library(amap)
library(MASS)
library(RODBC)



# Transform quantities to percents fished in the logevent
transformation_proportion=function(tab){
  res=as.matrix(tab)
  n=nrow(tab)
  p=ncol(tab)
  for (i in 1:n){
    sommeligne=sum(res[i,])
    if(sommeligne==0){
      res[i,]=rep(0,p)
    }else{
      res[i,]=res[i,]*(100/sommeligne)
    }
  }
  return(res)
}


# Transposing data (changing variables into individuals)
table_variables=function(data){
  n=nrow(data)
  res1=t(as.matrix(data[1:round(n/2),]))
  res2=t(as.matrix(data[(round(n/2)+1):n,]))
  res=cbind(res1,res2)
  row.names(res)=colnames(data)
  colnames(res)=row.names(data)
  return(res)
}


# Scree-test
scree=function(eig){
  n=length(eig)
  delta=numeric(n)
  epsilon=numeric(n)
  delta[2]=eig[2]-eig[1]
  for (i in 3:n){
    delta[i]=eig[i]-eig[i-1]
    epsilon[i]=delta[i]-delta[i-1]
  }
  data=matrix(0,nrow=n,ncol=3)
  data=cbind(valeurs_propres=eig, delta=delta, epsilon=epsilon)
  return(data)
}


# Removing the cluster with the smallest mean of capture
select_species=function(data,groupes_cah){
  nb.classes=length(levels(as.factor(groupes_cah)))
  moyennes=numeric(nb.classes)
  for(i in 1:nb.classes){
    namegp=names(which(groupes_cah==i))
    effgp=length(which(groupes_cah==i))
    moyennes[i]=sum(data[namegp])/effgp
  }
  indice.autre=which.min(moyennes)
  noms=names(which(groupes_cah!=indice.autre))
  return(list(noms,indice.autre))
}


# Building the table with main species
building_tab_pca=function(data,especes){
  p=ncol(data)
  noms=colnames(data)
  ind_princ=which(is.element(noms,especes))
  princ=data[,ind_princ]
  return(princ)
}


# Function computing the test-values
test.values=function(groupes,data){
                                                                         
  n=nrow(data)
  p=ncol(data)
  noms_var=colnames(data)
  nb_groupes=length(levels(as.factor(groupes)))
  noms_groupes=character(nb_groupes)

  stats_globales=matrix(0,nr=p,ncol=2)
  row.names(stats_globales)=noms_var
  colnames(stats_globales)=c("moyenne","variance")
  for (i in 1:p){
    stats_globales[i,1]=mean(data[,noms_var[i]])
    stats_globales[i,2]=var(data[,noms_var[i]])
  }

  res=matrix(0,nr=p,ncol=nb_groupes)
  row.names(res)=noms_var

  for (j in 1:nb_groupes){
    groupe=which(groupes==j)                        
    n_k=length(groupe)

    for (i in 1:p){
      mu_k=mean(data[groupe,noms_var[i]])
      mu=stats_globales[noms_var[i],"moyenne"]
      V=stats_globales[noms_var[i],"variance"]
      V_mu_k=(n-n_k)*V/(n_k*(n-1))
      
      if(V_mu_k==0){
        Valeur_test=0
      }else{
        Valeur_test=(mu_k-mu)/sqrt(V_mu_k)
      }
                                                
      res[i,j]=Valeur_test
      rm(Valeur_test)
    }
    rm(groupe)
    noms_groupes[j]=paste("groupe",j,sep="_")
  }
  colnames(res)=noms_groupes
  return(res)
}


# Fonction determining the target species
targetspecies=function(resval){
  p=nrow(resval)
  nbgp=ncol(resval)
  
  tabnumespcib=data.frame()
  tabnomespcib=data.frame()
   
  for(i in 1:nbgp){
    # qnorm(0.975,mean=0,sd=1)=1.96
    numespcib=which(resval[,i]>1.96)   
    numespcibdec=numespcib[order(resval[numespcib,i],decreasing=T)]           
    nomespcib=names(numespcibdec)
       
    nbespgpcib=length(numespcib)

    if(nbespgpcib>0){
      for (j in 1:nbespgpcib){
        tabnumespcib[i,j]=numespcibdec[j]
        tabnomespcib[i,j]=nomespcib[j]
      }                                                       
    }else{
        tabnumespcib[i,]=NA
        tabnomespcib[i,]=NA
    }   
  }
  tabnumespcib=as.matrix(tabnumespcib)
  tabnomespcib=as.matrix(tabnomespcib)
  return(list(tabnumespcib=tabnumespcib,tabnomespcib=tabnomespcib))
}


# Calcule of within variance of a cluster (square distance between each row of 
# the cluster and the cluster's center of gravity)
# we calculate the distance row by row
withinVar=function(oneRowOfCluster,centerOfGravityClusti){
  CoGWithOneRow=numeric()
  CoGWithOneRow=rbind(centerOfGravityClusti, oneRowOfCluster)
  distRowCoG=dist(CoGWithOneRow)^2
  return(distRowCoG)
}