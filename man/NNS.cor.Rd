% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Correlation.R
\name{NNS.cor}
\alias{NNS.cor}
\title{NNS Correlation}
\usage{
NNS.cor(x, y = NULL, order = NULL, degree = NULL)
}
\arguments{
\item{x}{a numeric vector, matrix or data frame.}

\item{y}{\code{NULL} (default) or a numeric vector with compatible dimsensions to \code{x}.}

\item{order}{integer; Controls the level of quadrant partitioning.  Defualts to \code{(order = NULL)}.  Errors can generally be rectified by setting \code{(order = 1)}.}

\item{degree}{integer; \code{(degree = 0)} is frequency based correlations, while \code{(degree = 1)} is for area based correlations.  Defaults to \code{(degree = 0)} for smaller number of observations.}
}
\value{
Returns nonlinear correlation coefficient between two variables, or nonlinear correlation matrix for matrix input.
}
\description{
Returns the nonlinear correlation between two variables based on higher order partial moment matrices measured by frequency or area.
}
\note{
p-values and confidence intervals can be obtained from sampling random permutations of \code{y_p} and running \code{NNS.dep(x,y_p)} to compare against a null hypothesis of 0 correlation or independence between \code{x,y}.

See \link{NNS.dep} for examples.
}
\examples{
\dontrun{
set.seed(123)
## Pairwise Correlation
x <- rnorm(100) ; y <- rnorm(100)
NNS.cor(x, y)

## Correlation Matrix
x <- rnorm(100) ; y <- rnorm(100) ; z<-rnorm(100)
B <- cbind(x, y, z)
NNS.cor(B)}

}
\references{
Viole, F. and Nawrocki, D. (2013) "Nonlinear Nonparametric Statistics: Using Partial Moments"
\url{https://www.amazon.com/dp/1490523995}
}
\author{
Fred Viole, OVVO Financial Systems
}
