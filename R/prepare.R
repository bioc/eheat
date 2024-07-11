#' Prepare ExtendedHeatmap
#'
#' @param object A [ExtendedHeatmap][eheat] or [ExtendedAnnotation][eanno]
#' object.
#' @param ... Not used currently.
#' @return An modified `object` with the same class.
#' @examples
#' # eheat_prepare(eheat(matrix(rnorm(81), nrow = 9)))
#' @keywords internal
eheat_prepare <- function(object, ...) UseMethod("eheat_prepare")

#' @export
#' @rdname eheat_prepare
eheat_prepare.default <- function(object, ...) object
