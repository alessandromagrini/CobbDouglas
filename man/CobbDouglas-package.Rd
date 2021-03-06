\name{CobbDouglas-package}
\alias{CobbDouglas-package}
\docType{package}
\title{Efficiency analysis using the Cobb-Douglas production frontier}
\description{Functionalities to estimate a Cobb-Douglas production frontier from sample data through constrained least squares.
It is possible to set a lower bound for the elasticities and/or the desired returns to scale, to predict the maximum producible output or technical efficiency, and to obtain boostrap confidence intervals for parameters and technical efficiencies.}
\details{
  \tabular{ll}{
  Package: \tab CobbDouglas\cr
  Type: \tab Package\cr
  Version: \tab 0.1\cr
  Date: \tab 2021-05-12\cr
  License: \tab GPL-2
  }
The main functions of the package are:
\itemize{
  \item{\link{CobbDouglas}, }{to estimate the frontier from sample data;}
  \item{\link{predict.CobbDouglas}, }{to predict the maximum producible output or technical efficiency;}
  \item{\link{CobbDouglas_boot}, }{to obtain bootstrap confidence intervals for parameters and technical efficiencies.}
  }
}
\author{Alessandro Magrini <alessandro.magrini@unifi.it>}
\references{
C. W. Cobb and P. H. Douglas (1928). A Theory of Production. \emph{American Economic Review}, 18: 139-165.
}
