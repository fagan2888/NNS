% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dy_d_wrt.R
\name{dy.d_}
\alias{dy.d_}
\title{Partial Derivative dy/d_[wrt]}
\usage{
dy.d_(
  x,
  y,
  wrt,
  eval.points = "median",
  folds = 5,
  mixed = FALSE,
  plot = FALSE,
  messages = TRUE
)
}
\arguments{
\item{x}{a numeric matrix or data frame.}

\item{y}{a numeric vector with compatible dimsensions to \code{x}.}

\item{wrt}{integer; Selects the regressor to differentiate with respect to.}

\item{eval.points}{numeric or options: ("mean", median", "last", "all"); Regressor points to be evaluated.  \code{(eval.points = "median")} (default) to find the average partial derivative at the median of the variable with respect to.  Set to \code{(eval.points = "last")} to find the average partial derivative at the last observation of the variable with respect to (relevant for time-series data).  Set to \code{(eval.points="mean")} to find the average partial derivative at the mean of the variable with respect to. Set to \code{(eval.points = "all")} to find the overall partial derivative at every observation of the variable with respect to.}

\item{folds}{integer; 5 (default) Sets the number of \code{folds} in the \link{NNS.stack} procedure for optimal \code{n.best} parameter.}

\item{mixed}{logical; \code{FALSE} (default) If mixed derivative is to be evaluated, set \code{(mixed = TRUE)}.}

\item{plot}{logical; \code{FALSE} (default) Set to \code{(plot = TRUE)} to view plot.
Default setting is \code{(noise.reduction = "mean")}.}

\item{messages}{logical; \code{TRUE} (default) Prints status messages of cross-validation on \code{n.best} parameter for \link{NNS.reg}.}
}
\value{
Returns:
\itemize{
\item{\code{dy.d_(...)$"First Derivative"}} the 1st derivative
\item{\code{dy.d_(...)$"Second Derivative"}} the 2nd derivative
\item{\code{dy.d_(...)$"Mixed Derivative"}} the mixed derivative (for two independent variables only).
}
}
\description{
Returns the numerical partial derivate of \code{y} with respect to [wrt] any regressor for a point of interest.  Finite difference method is used with \link{NNS.reg} estimates as \code{f(x + h)} and \code{f(x - h)} values.
}
\examples{
\dontrun{
set.seed(123) ; x_1 <- runif(100) ; x_2 <- runif(100) ; y <- x_1 ^ 2 * x_2 ^ 2
B <- cbind(x_1, x_2)

## To find average partial derivative of y wrt 1st regressor, only supply 1 value in [eval.points]
dy.d_(B, y, wrt = 1, eval.points = c(.5))

dy.d_(B, y, wrt = 1, eval.points = mean(B[, 1]))

## To find derivatives of y wrt 1st regressor and specified 2nd regressor
dy.d_(B, y, wrt = 1, eval.points = c(.5, .5))


## Known function analysis: [y = a ^ 2 * b ^ 2]
x_1 <- seq(0, 1, .1) ; x_2 <- seq(0, 1, .1)
B <- expand.grid(x_1, x_2) ; y <- B[ , 1] ^ 2 * B[ , 2] ^ 2
dy.d_(B, y, wrt = 1, eval.points = c(.5, .5))}
}
\references{
Viole, F. and Nawrocki, D. (2013) "Nonlinear Nonparametric Statistics: Using Partial Moments"
\url{https://www.amazon.com/dp/1490523995}
}
\author{
Fred Viole, OVVO Financial Systems
}
