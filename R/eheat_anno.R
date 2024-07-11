#' Construct HeatmapAnnotation object
#'
#' This function is similar to the
#' [HeatmapAnnotation][ComplexHeatmap::HeatmapAnnotation] function, but it
#' automatically guesses the `which` argument when combined with the [eheat]
#' function. Additionally, the `eheat_anno` function provides alternative
#' options to set the height(or width) of each individual annotation or adjust
#' the dimensions of the entire set of column/row annotations simultaneously
#' using the `annotation_size` or `size` parameters.
#'
#' @param ... Additional arguments passed to
#' [HeatmapAnnotation][ComplexHeatmap::HeatmapAnnotation].
#' @param annotation_size `Height/width` of each annotation for column/row
#' annotation.
#' @param size `Height/width` of the whole annotations for column/row
#' annotation.
#' @param which A string of `"row"` or `"column"`.
#' @return A [HeatmapAnnotation][ComplexHeatmap::HeatmapAnnotation-class]
#' object.
#' @examples
#' # No need to specify `which` argument if combined with `ggheat` or `eheat`
#' g <- ggplot(mpg, aes(displ, hwy, colour = class)) +
#'     geom_point()
#' m <- matrix(rnorm(100), 10)
#' ggheat(m,
#'     top_annotation = eheat_anno(
#'         ggplot = anno_gg(g, "panel",
#'             clip = "on",
#'             size = unit(6, "cm"),
#'             show_name = FALSE
#'         )
#'     )
#' )
#' @export
eheat_anno <- function(..., annotation_size = NULL, size = NULL, which = NULL) {
    which <- eheat_which(which)
    old <- eheat_env_set("current_annotation_which", which)
    on.exit(eheat_env_set("current_annotation_which", old), add = TRUE)
    if (!rlang::is_named(dots <- rlang::list2(...))) {
        cli::cli_abort("all arguments must be named")
    }
    if (which == "row") {
        dots$annotation_width <- dots$annotation_width %||% annotation_size
        dots$width <- dots$width %||% size
        if (!is.null(.subset2(dots, "annotation_height"))) {
            cli::cli_warn(
                "cannot set {.arg annotation_height} for row annotation"
            )
            dots$annotation_height <- NULL
        }
        if (!is.null(.subset2(dots, "height"))) {
            cli::cli_warn("cannot set {.arg height} for row annotation")
            dots$height <- NULL
        }
    } else {
        dots$annotation_height <- dots$annotation_height %||% annotation_size
        dots$height <- dots$height %||% size
        if (!is.null(.subset2(dots, "annotation_width"))) {
            cli::cli_warn(
                "cannot set {.arg annotation_width} for column annotation"
            )
            dots$annotation_width <- NULL
        }
        if (!is.null(.subset2(dots, "width"))) {
            cli::cli_warn("cannot set {.arg width} for column annotation")
            dots$width <- NULL
        }
    }
    rlang::inject(ComplexHeatmap::HeatmapAnnotation(!!!dots, which = which))
}
