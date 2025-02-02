% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/eheat_anno.R
\name{eheat_anno}
\alias{eheat_anno}
\title{Construct HeatmapAnnotation object}
\usage{
eheat_anno(..., annotation_size = NULL, size = NULL, which = NULL)
}
\arguments{
\item{...}{Additional arguments passed to
\link[ComplexHeatmap:HeatmapAnnotation]{HeatmapAnnotation}.}

\item{annotation_size}{\code{Height/width} of each annotation for column/row
annotation.}

\item{size}{\code{Height/width} of the whole annotations for column/row
annotation.}

\item{which}{A string of \code{"row"} or \code{"column"}.}
}
\value{
A \link[ComplexHeatmap:HeatmapAnnotation-class]{HeatmapAnnotation}
object.
}
\description{
This function is similar to the
\link[ComplexHeatmap:HeatmapAnnotation]{HeatmapAnnotation} function, but it
automatically guesses the \code{which} argument when combined with the \link{eheat}
function. Additionally, the \code{eheat_anno} function provides alternative
options to set the height(or width) of each individual annotation or adjust
the dimensions of the entire set of column/row annotations simultaneously
using the \code{annotation_size} or \code{size} parameters.
}
\examples{
# No need to specify `which` argument if combined with `ggheat` or `eheat`
g <- ggplot(mpg, aes(displ, hwy, colour = class)) +
    geom_point()
m <- matrix(rnorm(100), 10)
ggheat(m,
    top_annotation = eheat_anno(
        ggplot = anno_gg(g, "panel",
            clip = "on",
            size = unit(6, "cm"),
            show_name = FALSE
        )
    )
)
}
