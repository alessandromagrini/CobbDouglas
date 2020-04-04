# estimate the frontier
CobbDouglas <-  function(y.name,x.names=NULL,data,beta.sum=NULL) {
  # check data
  if(missing(data)) stop("Missing argument 'data'",call.=F)
  if(!identical(class(data),"data.frame")) stop("Argument 'data' must be a data.frame",call.=F)
  if(missing(y.name)) stop("Missing argument 'y.name'",call.=F)
  if(!is.character(y.name) || length(y.name)!=1) stop("Argument 'y.name' must be a character vector of length 1",call.=F)
  auxchk <- setdiff(y.name,colnames(data))
  if(length(auxchk)>0) stop("Variable '",auxchk[1],"' not found",sep="",call.=F)
  #if(missing(x.names)) stop("Missing argument 'x.names'",call.=F)
  if(is.null(x.names)) x.names <- setdiff(colnames(data),y.name)
  if(!is.character(x.names) || length(x.names)<1) stop("Argument 'x.names' must be a character vector of length 1 or greater",call.=F)
  auxchk <- setdiff(x.names,colnames(data))
  if(length(auxchk)>0) stop("Variable '",auxchk[1],"' not found",sep="",call.=F)
  if(sum(is.na(data[,c(y.name,x.names)]))>0) stop("Missing values found in data",call.=F)
  if(length(beta.sum)>1) beta.sum <- beta.sum[1]
  if(!is.null(beta.sum) & (!is.numeric(beta.sum) || beta.sum<=0)) stop("Argument 'beta.sum' must be a strictly positive value",call.=F)
  n <- nrow(data)
  yorig <- data[,y.name]
  y <- log(data[,y.name])
  xval <- as.matrix(log(data[,x.names,drop=F]))
  X <- cbind(rep(1,nrow(xval)),xval)
  p <- length(x.names)
  #
  if(!is.null(beta.sum)) {
    ynew <- y-beta.sum*X[,p+1]
    if(p==1) {
      Xnew <- X[,1,drop=F]
      x0 <- matrix(nrow=0,ncol=p)
      r0 <- c()
      } else {
      x0 <- matrix(0,nrow=p-1,ncol=p)
      for(i in 1:(p-1)) {
        x0[i,i] <- 1 
        }
      Xnew <- X[,1:p,drop=F]
      for(i in 2:p) {
        Xnew[,i] <- X[,i]-X[,p+1]
        }
      r0 <- rep(0,p-1)
      }
    } else {
    x0 <- matrix(0,nrow=p,ncol=p+1)
    for(i in 1:p) {
      x0[i,i+1] <- 1 
      }
    r0 <- rep(0,p)
    ynew <- y
    Xnew <- X
    }
  #
  # optimization
  R <- rbind(Xnew,x0)
  r <- c(ynew,r0)
  res <- solve.QP(Dmat=t(Xnew)%*%Xnew, dvec=t(ynew)%*%Xnew, Amat=t(R), bvec=r)
  par <- res$solution
  if(!is.null(beta.sum)) {
    if(p==1) {
      par <- c(par,beta.sum)      
      } else {
      auxb <- par[2:p]
      par <- c(par,beta.sum-sum(auxb))
      }
    }
  #
  ystar <- c(X%*%par)
  e <- y-ystar
  xlab <- x.names
  parOK <- par
  parOK[1] <- exp(par[1])
  names(parOK) <- c("(tau)",xlab)
  fitted <- exp(ystar)
  effy <- exp(y)/fitted
  effx <- effy^(1/sum(par[2:length(par)]))
  effMat <- round(data.frame(y.side=effy,x.side=effx),3)
  fittedMat <- data.frame(log.scale=ystar,orig.scale=fitted)
  residMat <- data.frame(log.scale=y-ystar,orig.scale=yorig-fitted)  
  rownames(effMat) <- rownames(fittedMat) <- rownames(residMat) <- rownames(data)
  OUT <- list(parameters=parOK,efficiency=effMat,fitted=fittedMat,residuals=residMat,
    beta.sum=beta.sum,y.name=y.name,x.names=x.names,data=data[,c(y.name,x.names)])
  class(OUT) <- "CobbDouglas"
  OUT
  }

# print method
print.CobbDouglas <- function(x,...) {
  cat("Cobb-Douglas frontier with ",length(x$x.names)," input variables",sep="","\n")
  cat(" ------------------------------------------ ","\n")
  cat("| $parameters   Parameter estimates        |","\n")
  cat("| $efficiency   Technical efficiencies     |","\n")
  cat("| $fitted       Fitted values              |","\n")
  cat("| $residuals    Residuals                  |","\n")
  cat(" ------------------------------------------ ","\n")
  cat("summary() and predict() methods are available","\n")
  cat("?CobbDouglas to see the documentation","\n")
  }

# summary method
summary.CobbDouglas <- function(object,...) {
  par <- object$parameters
  res <- list(n.input=length(object$x.names),parameters=par,
    sigma=apply(object$residuals,2,function(y){sd(y)*(length(y)-1)/length(y)}),
    efficiency=summary(object$efficiency))
  class(res) <- "summary.CobbDouglas"
  res
  }

# print method for the summary method
print.summary.CobbDouglas <- function(x,...) {
  cat("Cobb-Douglas frontier with ",x$n.input," input variables",sep="","\n","\n")
  cat("Estimated parameters:","\n")
  print(x$parameters)
  cat("\n")
  cat("Residual std. dev.: ",x$sigma[1]," (log. scale)  ",x$sigma[2]," (orig. scale)",sep="","\n","\n")
  cat("Technical efficiencies: ","\n")
  print(x$efficiency)
  }

# predict method
predict.CobbDouglas <- function(object,newdata=NULL,type="output",...) {
  if(!is.null(newdata) && !identical(class(newdata),"data.frame")) stop("Argument 'newdata' must be a data.frame",call.=F)
  if(length(type)>1) type <- type[1]
  auxtype <- substr(c("output","efficiency"),1,nchar(type))
  if((type%in%auxtype)==F) stop("Argument 'type' must be either 'output' or 'efficiency'",call.=F)
  if(is.null(newdata)) {
    if(type==auxtype[2]) object$efficiency else object$fitted
    } else {
    auxpar <- par <- object$parameters
    par[1] <- log(auxpar[1])
    xnam <- object$x.names
    if(sum(is.na(newdata[,xnam]))>0) stop("Missing values found in 'newdata'",call.=F)
    auxchk <- setdiff(xnam,colnames(newdata))
    if(length(auxchk)>0) stop("Input variable '",auxchk[1],"' not found",sep="",call.=F)
    xval <- as.matrix(log(newdata[,xnam,drop=F]))
    X <- cbind(rep(1,nrow(xval)),xval)
    res <- c(exp(X%*%par))
    names(res) <- rownames(newdata)
    if(type==auxtype[2]) {
      ynam <- object$y.name
      if((ynam%in%colnames(newdata))==F) stop("Output variable '",ynam,"' not found",sep="",call.=F)
      if(sum(is.na(newdata[,ynam]))>0) stop("Missing values found in 'newdata'",call.=F)
      effy <- round(newdata[,ynam]/res,3)
      effx <- round(effy^(1/sum(par[2:length(par)])),3)
      if(sum(effy>1)|sum(effx>1)) warning("Some points are above the frontier")
      effMat <- cbind(y.side=effy,x.side=effx)
      rownames(effMat) <- names(res)  
      data.frame(newdata[,c(ynam,xnam)],effMat)
      } else {
      res
      }
    }
  }

# plot method
plot.CobbDouglas <- function(x,xlab=NULL,ylab=NULL,...) {
  xnam <- x$x.names
  if(length(xnam)!=1) stop("Currently implemented only for 1 input variable",call.=F)
  ynam <- x$y.name
  data <- x$data
  y <- data[,ynam]
  v <- data[,xnam]
  xseq <- seq(0, max(v), length=1000)
  newdat <- data.frame(xseq)
  colnames(newdat) <- xnam
  yseq <- predict(x, newdata=newdat)
  if(is.null(xlab)) xlab <- xnam
  if(is.null(ylab)) ylab <- ynam
  plot(v, y, ylim=c(0,max(yseq)), xlab=xlab, ylab=ylab, ...)
  grid()
  lines(xseq, yseq, col=2)
  }

# bootstrap
CobbDouglas_boot <- function(x,nboot=500,conf=0.95) {
  if(!identical(class(x),"CobbDouglas")) stop("Argument 'x' must be an object of class 'CobbDouglas'",call.=F)
  if(length(nboot)>1) nboot <- nboot[1]
  if(!is.numeric(nboot) || round(nboot)!=nboot || nboot<50) stop("Argument 'nboot' must be an integer number greater or equal than 50",call.=F)
  if(length(conf)>1) conf <- conf[1]
  if(!is.numeric(conf) || conf<=0 || conf>=1) stop("Argument 'conf' must be in the interval(0,1)",call.=F)
  conf <- round(conf,4)
  data <- x$data
  ynam <- x$y.name
  xnam <- x$x.names
  k <- x$beta.sum
  bhat <- matrix(nrow=0,ncol=length(x$parameters))
  ystar <- matrix(nrow=0,ncol=nrow(data))
  count <- 0
  while(count<nboot) {
    ind <- sample(1:nrow(data),nrow(data),replace=T)
    idat <- data[ind,]
    imod <- CobbDouglas(y.name=ynam,x.names=xnam,data=idat,beta.sum=k)
    bhat <- rbind(bhat,imod$parameters)
    ystar <- rbind(ystar,imod$fitted$orig.scale)
    count <- count+1
    }
  rownames(bhat) <- rownames(ystar) <- NULL
  colnames(bhat) <- names(x$parameters)
  colnames(ystar) <- rownames(data)
  par <- x$parameters
  bsum_res <- apply(bhat[,2:ncol(bhat),drop=F],1,sum)
  bsum_est <- sum(par[2:length(par)])
  bsum_nam <- "(beta.sum)"
  b_res <- cbind(bhat,bsum_res)
  est <- c(par,bsum_est)
  summ <- cbind(est,t(apply(b_res,2,quantile,prob=c(1-conf,1+conf)/2)))
  summ_y <- cbind(x$fitted$orig.scale,t(apply(ystar,2,quantile,prob=c(1-conf,1+conf)/2)))  
  colnames(summ) <- colnames(summ_y) <- c("Estimate",paste(round(c(1-conf,1+conf)/2*100,2),"%",sep=""))
  rownames(summ) <- c("(tau)",names(par)[2:length(par)],bsum_nam)
  rownames(summ_y) <- rownames(data)
  res <- list(parameters=summ,fitted=summ_y)  #boot.parameters=bhat,boot.fitted=ystar)
  class(res) <- "CobbDouglas_boot"
  res
  }

# print method for class CobbDouglas_boot
print.CobbDouglas_boot <- function(x, ...) {
  print(x$parameters)
  }