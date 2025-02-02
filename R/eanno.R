#' @inherit ComplexHeatmap::AnnotationFunction
#' @param draw_fn A function which defines how to draw the annotation. See
#' [ComplexHeatmap
#' Manual](https://jokergoo.github.io/ComplexHeatmap-reference/book/heatmap-annotations.html#implement-new-annotation-functions)
#' for details.
#'
#' The function must have at least Four arguments: `index`, `k`, `n` (the names
#' of the arguments can be arbitrary) where `k` and `n` are optional.  `index`
#' corresponds to the indices of rows or columns of the heatmap. The value of
#' `index` is not necessarily to be the whole row indices or column indices in
#' the heatmap. It can also be a subset of the indices if the annotation is
#' split into slices according to the split of the heatmap.  `index` is
#' reordered according to the reordering of heatmap rows or columns (e.g. by
#' clustering). So, `index` actually contains a list of row or column indices
#' for the current slice after row or column reordering.
#'
#' `k` corresponds to the current slice and `n` corresponds to the total number
#' of slices.
#'
#' You can always use `self` to indicates the `data` attached in this
#' annotation.
#'
#' @param ... Additional arguments passed on to `draw_fn`. Only named arguments
#' can be subsettable.
#' @param data A `matrix` or `data.frame`, if it is a simple vector, it will be
#' converted to a one-column matrix. If `NULL`, the matrix from the heatmap will
#' be used. You can also provide a function to transform the matrix.
#' @param size The `width/height` of the plotting region (the viewport) that the
#' annotation is drawn. If it is a `row` annotation, `size` is regarded as the
#' `width`, otherwise, the `height`. `size` must be an absolute
#' [unit][grid::unit] object.  Since the
#' [AnnotationFunction][ComplexHeatmap::AnnotationFunction-class] object is
#' always contained by the
#' [SingleAnnotation-class][ComplexHeatmap::SingleAnnotation-class] object, you
#' can only set the `width` of row annotations or `height` of column
#' annotations, while e.g. the `height` of the row annotation and `width` of the
#' column annotations is always `unit(1, "npc")` which means it always fully
#' filled in the parent `SingleAnnotation` and only in
#' [SingleAnnotation][ComplexHeatmap::SingleAnnotation] or even
#' [HeatmapAnnotation][ComplexHeatmap::HeatmapAnnotation] can adjust the
#' `height` of the row annotations or `width` of the column annotations.
#' @inheritParams ComplexHeatmap::AnnotationFunction
#' @param subset_rule A list of function to subset variables in `...`.
#' @param fun_name Name of the annotation function, only used for message.
#' @param legends_margin,legends_panel A list of
#' [Legends][ComplexHeatmap::Legends-class] objects. `legends_margin` will be
#' added in the `annotation_legend_list` of
#' [draw][ComplexHeatmap::draw,HeatmapList-method]. `legends_panel` will be
#' plotted in the annotation panel. See [Legend][ComplexHeatmap::Legend] for
#' details. Only object with [make_legends] methods can be put in
#' `legends_margin`. Only object with [draw][draw-method] methods can be put in
#' `legends_panel`.
#' @details
#' `eanno` is similar with
#' [AnnotationFunction][ComplexHeatmap::AnnotationFunction], but `eanno` won't
#' change the function environment of `draw_fn`. So it's safe to use `eanno` in
#' pacakge development, particularly when dealing with internal functions in the
#' package namespace. In addition, all data has been attached in this object.
#' @examples
#' library(grid)
#' x <- 1:10
#' anno <- eanno(
#'     draw_fn = function(index, k, n) {
#'         n <- length(index)
#'         pushViewport(viewport(xscale = c(0.5, n + 0.5), yscale = c(0, 10)))
#'         grid.rect()
#'         grid.points(1:n, x[index], default.units = "native")
#'         if (k == 1) grid.yaxis()
#'         popViewport()
#'     },
#'     size = unit(2, "cm")
#' )
#' m <- rbind(1:10, 11:20)
#' eheat(m, top_annotation = eheat_anno(foo = anno))
#' eheat(m, top_annotation = eheat_anno(foo = anno), column_km = 2)
#'
#' anno <- eanno(
#'     function(index, k, n, self) {
#'         n <- length(index)
#'         pushViewport(viewport(xscale = c(0.5, n + 0.5), yscale = c(0, 10)))
#'         grid.rect()
#'         grid.points(1:n, self[index, drop = TRUE], default.units = "native")
#'         if (k == 1) grid.yaxis()
#'         popViewport()
#'     },
#'     data = rnorm(10L), subset_rule = TRUE,
#'     size = unit(2, "cm")
#' )
#' draw(anno)
#' draw(anno[1:2])
#' @seealso [AnnotationFunction][ComplexHeatmap::AnnotationFunction]
#' @return A `ExtendedAnnotation` object.
#' @export
eanno <- function(draw_fn, ..., data = NULL,
                  size = NULL, show_name = TRUE, which = NULL,
                  subset_rule = NULL,
                  legends_margin = NULL, legends_panel = NULL,
                  fun_name = NULL) {
    if (ht_opt$verbose) {
        cli::cli_inform("construct ExtendedAnnotation with {.fn eanno}")
    }
    # ComplexHeatmap::AnnotationFunction() will change the function
    # environment of `anno@fun`
    # here: we use eanno instead, in this way, the function in the
    #       package namespace can be used directly
    draw_fn <- allow_lambda(draw_fn)
    assert_(draw_fn, is.function, "a function")
    data <- allow_lambda(data)
    if (is.null(data)) {
        n <- NA
    } else if (is.function(data)) {
        n <- NA
    } else {
        data <- build_anno_data(data)
        n <- nrow(data)
    }
    which <- eheat_which(which)

    dots <- rlang::list2(...)

    # prepare subset rules ---------------------------------
    # https://github.com/jokergoo/ComplexHeatmap/blob/7d95ca5cf533b98bd0351eecfc6805ad30c754c0/R/AnnotationFunction-class.R#L270
    if (is.null(subset_rule)) {
        subsettable <- FALSE
        subset_rule <- list()
    } else if (is.logical(subset_rule)) {
        if (!is_scalar(subset_rule)) {
            cli::cli_abort("{.arg subset_rule} must be a single boolean value")
        } else if (is.na(subset_rule)) {
            cli::cli_abort("{.arg subset_rule} cannot be `NA`")
        }

        if (subsettable <- subset_rule) {
            subsettable_args <- dots[rlang::have_name(dots)]
            if (length(subsettable_args)) {
                subset_rule <- rep_len(TRUE, length(subsettable_args))
                names(subset_rule) <- rlang::names2(subsettable_args)
            } else {
                subset_rule <- list()
            }
        }
    } else if (is.list(subset_rule)) {
        if (!rlang::is_named2(subset_rule)) {
            cli::cli_abort("{.arg subset_rule} must be named")
        }
        missing_rules <- setdiff(
            rlang::names2(subset_rule),
            rlang::names2(dots)
        )
        if (length(missing_rules)) {
            cli::cli_abort("Cannot find {.val {missing_rules}} in {.arg ...}")
        }
        subset_rule <- lapply(subset_rule, allow_lambda)
        if (!all(vapply(subset_rule, is.function, logical(1L)))) {
            cli::cli_abort("{.arg subset_rule} must be a list of function")
        }
        subsettable <- TRUE
    }

    # contruct ExtendedAnnotation -----------------------------
    anno <- methods::new("ExtendedAnnotation")
    anno@dots <- dots
    anno@data <- data
    anno@which <- which
    anno@fun <- unclass(draw_fn)
    anno@fun_name <- fun_name %||% "eanno"
    anno_size <- anno_width_and_height(which, size, unit(1, "cm"))
    anno@width <- .subset2(anno_size, "width")
    anno@height <- .subset2(anno_size, "height")
    anno@show_name <- show_name
    anno@n <- n
    anno@data_scale <- c(0L, 1L)
    anno@subsettable <- subsettable
    anno@subset_rule <- subset_rule

    # we change `var_env` into the environment of `@fun`
    anno@var_env <- environment(anno@fun)

    # assign legends ---------------------------
    if (is.null(legends_margin)) {
        legends_margin <- list()
    } else {
        legends_margin <- wrap_legend(legends_margin)
    }
    anno@legends_margin <- legends_margin
    if (is.null(legends_panel)) {
        legends_panel <- list()
    } else {
        legends_panel <- wrap_legend(legends_panel)
    }
    anno@legends_panel <- legends_panel
    anno
}

#' @export
`[.ExtendedAnnotation` <- function(x, i) {
    if (missing(i)) return(x) # styler: off
    if (!x@subsettable) {
        cli::cli_abort("{.arg x} is not subsettable.")
    }

    # subset dots ---------------------------------------
    rules <- x@subset_rule
    x@dots[rlang::have_name(x@dots)] <- imap(
        x@dots[rlang::have_name(x@dots)], function(var, nm) {
            rule <- .subset2(rules, nm)
            if (is.null(rule) || isFALSE(rule)) {
                var
            } else if (isTRUE(rule)) {
                # subset element
                if (inherits(var, c("tbl_df", "data.table"))) {
                    # For tibble and data.table, no `drop` argument
                    var[i, ]
                } else if (is.matrix(var) || is.data.frame(var)) {
                    # For matrix and data.frame
                    var[i, , drop = FALSE]
                } else if (inherits(var, "gpar")) {
                    # For gpar object
                    subset_gp(var, i)
                } else if (is.vector(var) && !is_scalar(var)) {
                    # other vector object
                    var[i]
                }
            } else {
                rule(var, i)
            }
        }
    )

    # subset the annotation data ---------------------
    if (inherits(x@data, c("tbl_df", "data.table"))) {
        # For tibble and data.table, no `drop` argument
        x@data <- x@data[i, ]
    } else if (is.matrix(x@data) || is.data.frame(x@data)) {
        # For matrix and data.frame
        x@data <- x@data[i, , drop = FALSE]
    }
    if (is_scalar(x@n) && is.na(x@n)) return(x) # styler: off
    if (is.logical(i)) {
        x@n <- sum(i)
    } else if (is.numeric(i)) {
        if (all(i > 0L)) x@n <- length(i)
        if (all(i < 0L)) x@n <- x@n - length(i)
    }
    return(x)
}

#' @importClassesFrom ComplexHeatmap AnnotationFunction
#' @export
#' @rdname eanno
methods::setClass(
    "ExtendedAnnotation",
    slots = list(
        data = "ANY",
        dots = "list",
        legends_margin = "list",
        legends_panel = "list",
        initialized = "logical"
    ),
    prototype = list(
        data = NULL,
        dots = list(),
        legends_margin = list(),
        legends_panel = list(),
        initialized = FALSE
    ),
    contains = "AnnotationFunction"
)

methods::setValidity("ExtendedAnnotation", function(object) {
    data <- object@data
    if (!is.null(data) && !is.function(data) &&
        !(is.matrix(data) || inherits(data, "data.frame"))) {
        cli::cli_abort(paste(
            "{.code @data} must be a",
            "matrix or data.frame or a function or `NULL`"
        ))
    }
    TRUE
})

wrap_anno_fn <- function(object) {
    # prepare annotation function --------------------------
    data <- object@data
    dots <- object@dots
    fn <- object@fun
    args <- formals(fn)

    # is.null is a fast path for a common case; the %in% check is slower but
    # also catches the case where there's a `self = NULL` argument.
    if (!is.null(.subset2(args, "self")) || "self" %in% names(args)) {
        function(index, k, n) {
            rlang::inject(fn(index, k, n, !!!dots, self = data))
        }
    } else {
        function(index, k, n) {
            rlang::inject(fn(index, k, n, !!!dots))
        }
    }
}

#' @param object An [ExtendedAnnotation][eanno] object.
#' @param viewport A viewport for this annotation.
#' @param heatmap Heatmap object after clustering.
#' @param name A string, the name of the annotation.
#' @importFrom ComplexHeatmap make_layout
#' @export
#' @rdname internal-method
methods::setMethod(
    "make_layout", "ExtendedAnnotation",
    function(object, ..., viewport = NULL, heatmap = NULL, name = NULL) {
        # we initialize the ExtendedAnnotation object and extract the
        # legends
        which <- object@which
        if (is.null(name)) {
            id <- object@fun_name
        } else {
            id <- sprintf("%s (%s)", object@fun_name, name)
        }
        # prepare ExtendedAnnotation matrix data ---------------------------
        anno_data <- object@data
        if (is.null(heatmap)) {
            heat_matrix <- NULL
        } else {
            heat_matrix <- heatmap@matrix
        }
        if (is.null(heat_matrix) &&
            (is.null(anno_data) || is.function(anno_data))) {
            cli::cli_abort(paste(
                "You must provide data (matrix or data.frame) in", id,
                "in order to draw {.cls {fclass(object)}} directly"
            ))
        }
        if (is.null(anno_data)) {
            anno_data <- switch(which,
                row = heat_matrix,
                column = t(heat_matrix)
            )
        } else if (is.function(anno_data)) {
            mat <- switch(which,
                row = heat_matrix,
                column = t(heat_matrix)
            )
            anno_data <- tryCatch(
                build_anno_data(anno_data(mat)),
                invalid_class = function(cnd) {
                    cli::cli_abort(paste(
                        "{.fn @data} of {id} must return a {.cls matrix},",
                        "a simple vector, or a {.cls data.frame}."
                    ))
                }
            )
            if (nrow(anno_data) != nrow(mat)) {
                cli::cli_abort(paste(
                    "{.fn @data} of {id} return",
                    "{nrow(anno_data)} observation{?s}, but the heatmap",
                    "contain {nrow(mat)} for {which} annotation."
                ))
            }
        }
        object@n <- nrow(anno_data)
        object@data <- anno_data

        # call `eheat_prepare` to modify object after make_layout ----------
        # for `eheat_prepare`, the actual geom matrix has been added
        object <- eheat_prepare(
            object,
            viewport = viewport,
            heatmap = heatmap, name = name
        )

        initialized_eanno_fn <- wrap_anno_fn(object)
        force(viewport)
        object@fun <- function(index, k, n) {
            # in the first slice, we always insert annotation viewport
            if (k == 1L) {
                if (!is.null(viewport)) {
                    # current viewport: `draw,AnnotationFunction` function
                    # parent viewport - 1: `draw,HeatmapAnnotation` function
                    # parent viewport - 2: `draw,HeatmapAnnotation` function
                    # parent viewport - 3: `draw_annotation` function
                    #     for several annotation
                    # parent viewport - 4: `draw-internal` heatmap  function
                    # parent viewport - 5: `draw-internal` heatmap  function

                    # https://github.com/jokergoo/ComplexHeatmap/blob/7d95ca5cf533b98bd0351eecfc6805ad30c754c0/R/HeatmapList-draw_component.R#L668
                    # parent viewport - 6: `draw_heatmap_list` function

                    # parent viewport - 7: `draw_heatmap_list` function
                    #   -- "heatmap_{object@name}"
                    # parent viewport - 8: `draw_heatmap_list` function
                    #   -- "main_heatmap_list"
                    current_vp <- grid::current.viewport()$name
                    grid::upViewport(5L)
                    grid::pushViewport(viewport)
                    grid::seekViewport(current_vp)
                }
            }
            initialized_eanno_fn(index, k, n)
            # .eheat_decorate(vp_name, {
            #     grid::grid.rect(gp = gpar(fill = NA, col = "red"))
            #     grid::grid.text(
            #         vp_name,
            #         x = unit(1, "mm"),
            #         y = unit(1, "npc") - unit(1, "mm"),
            #         just = c("left", "top"),
            #         gp = gpar(fontsize = 8)
            #     )
            # })
            # in the last slice, we draw legends in the panel
            if (k == n && length(object@legends_panel)) {
                if (is.null(viewport)) {
                    lapply(object@legends_panel, draw)
                } else {
                    .eheat_decorate(
                        viewport$name,
                        lapply(object@legends_panel, draw)
                    )
                }
            }
        }
        object@initialized <- TRUE
        object
    }
)

#' @param index A vector of indices.
#' @param k The current slice index for the annotation if it is split.
#' @param n Total number of slices.
#' @param ... Additional arguments passed on to
# [draw-AnnotationFunction][ComplexHeatmap::draw,HeatmapAnnotation-method].
#' @export
#' @importFrom ComplexHeatmap draw
#' @export
#' @rdname draw-method
methods::setMethod(
    "draw", "ExtendedAnnotation",
    definition = function(object, index, k = 1L, n = 1L, ...) {
        if (ht_opt$verbose) {
            cli::cli_inform("annotation generated by {.fn {object@fun_name}}")
        }
        if (missing(index)) {
            if (is.na(object@n)) {
                cli::cli_abort(paste(
                    "You must provide {.arg index} to draw",
                    "{.cls {fclass(object)}} directly"
                ))
            }
            index <- seq_len(object@n)
        }
        # This is only used by ComplexHeatmap::Heatmap function
        # since `eheat` will initialize `eanno` when preparing the main
        # heatmap layout.
        if (k == 1L && !object@initialized) {
            heatmap <- NULL
            pos <- 1L
            nframes <- sys.nframe() - 1L # total parents
            # https://github.com/jokergoo/ComplexHeatmap/blob/7d95ca5cf533b98bd0351eecfc6805ad30c754c0/R/HeatmapList-draw_component.R#L670
            # trace back into `draw_heatmap_list()`
            # get slice informations from the draw function
            while (pos <= nframes) {
                env <- parent.frame(pos)
                if (is_from_eheat(env) &&
                    exists("ht_main", envir = env, inherits = FALSE) &&
                    is_call_from(pos, "draw_heatmap_list")) {
                    heatmap <- .subset2(env, "ht_main")
                }
                pos <- pos + 1L
            }
            if (is.null(heatmap) && n > 1L) {
                cli::cli_abort("Cannot initialize {.cls {object@name}}")
            }
            # we then initialize this annotation by call `make_layout`
            object <- make_layout(object, heatmap = heatmap)
        }
        # will create a new viewport
        methods::callNextMethod(
            object = object, index = index,
            k = k, n = n, ...
        )
    }
)

anno_width_and_height <- function(which, size = NULL,
                                  default = unit(10, "mm")) {
    size <- size %||% default
    if (!ComplexHeatmap::is_abs_unit(size)) {
        cli::cli_abort("{.arg size} must be an absolute unit.", )
    }
    if (which == "row") {
        list(width = size, height = unit(1L, "npc"))
    } else {
        list(width = unit(1L, "npc"), height = size)
    }
}
