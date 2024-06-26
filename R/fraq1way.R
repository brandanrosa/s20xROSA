#' fraq1way
#'
#' CI for Differences
#'
#' @param counts num
#' @param hypothprob probs
#' @param conf.level alpha
#' @param addCIs T/F
#' @param digits round
#' @param arrowwid yes
#' @param estimated you got it
#'
#' @return a named list
#' @export
#'
#' @examples \dontrun{fraq1way(imp)}
fraq1way = function(counts, hypothprob, conf.level = 0.95, addCIs = TRUE, digits = 4, arrowwid = 0.1, estimated = 0){
  varname = deparse(substitute(counts))
  if (length(dim(counts)) > 1)
    stop(paste("freq1way: Dimension of", varname, "greater than 1"))
  if (as.integer(estimated) != estimated)
    stop("freq1way: estimated must be an integer")

  dfs = length(counts) - 1


  if ((estimated < 0) | (estimated > dfs))
    stop(paste("freq1way: estimated must be between 0 and", dfs))
  n = sum(as.vector(counts))

  cat("data: ", varname, "   n =", n, "\n\n")
  ncats = length(counts)
  ncatsC2 = choose(ncats, 2)
  if ((any(counts != trunc(counts))) | (n < max(30, 5 * ncats)))
    warning("Expecting a vector of counts")
  if (is.null(names(counts)))
    names(counts) = 1:ncats
  conf.pc = 100 * conf.level
  phat = counts/n
  qval = abs(stats::qnorm((1 - conf.level)/(2 * ncats)))
  se = sqrt(phat * (1 - phat)/n)
  CIs = matrix(c(phat, phat - qval * se, phat + qval * se), ncol = 3, dimnames = list(names(counts), c("sample prop", "conf.lower", "conf.upper")))
  if (!missing(hypothprob)) {
    if (length(hypothprob) != ncats)
      stop("counts and hypothprob must have same length")
    CIs = cbind(CIs, hypothprob)
    colnames(CIs)[4] = "hypoth prob"
  }
  cat("Individual (large sample)", paste(conf.pc, "%", sep = ""), "CIs", "\n", "(adjusted for", ncats, "multiple comparisons)", "\n")
  print(round(CIs, 3), quote = FALSE)
  cat("\n")
  if (missing(hypothprob)) {
    chitest = stats::chisq.test(counts, p = rep(1, ncats)/ncats)
    chitest$p.value = 1 - stats::pchisq(chitest$statistic, dfs - estimated)
    #cat("Chi-square test for uniformity", "\n    ")
  } else {
    chitest = stats::chisq.test(counts, p = hypothprob)
    chitest$p.value = 1 - stats::pchisq(chitest$statistic, dfs - estimated)
    names(hypothprob) = names(counts)
    #cat("Chi-square test for hypothesized probabilities", "\n    ")
  }
  # cat(names(chitest$statistic), " = ", format(round(chitest$statistic, 4)), ", ", sep = "")
  # cat(paste(names(chitest$parameter), " = ", format(round(chitest$parameter - estimated, 3)), ",", sep = ""), "")
  # cat("p-value =", format.pval(chitest$p.value, digits = digits), "\n")
  if (any(chitest$exp < 5))
    warning("Chi-square approximation may be incorrect")
  cat("\n")
  uplim = ifelse(addCIs, max(phat + qval * se), max(phat))
  disp = 0
  modlength = 1
  if (missing(hypothprob)) {
    midp = graphics::barplot(phat, ylab = "Proportion", main = "Proportions at each level", sub = paste("[freq1way(", varname, ")]"), ylim = c(0, uplim))
    if (addCIs)
      graphics::abline(h = 1/ncats, lty = 2)
  } else {
    midp = graphics::barplot(rbind(phat, hypothprob), beside = TRUE, ylab = "Proportion", main = "Proportions at each level", sub = paste("[freq1way(", varname, ")]"), ylim = c(0, uplim), legend = c("sample", "hypothesis"))[1,
    ]
    disp = 0
    modlength = 2
  }
  if (addCIs)
    for (i in 1:length(midp)) graphics::arrows(midp[i] - disp, phat[i] - qval * se[i], midp[i] - disp, phat[i] + qval * se[i], code = 3, angle = 45, length = 0.9 * arrowwid/modlength)
  if (missing(hypothprob)) {
    matw = matrix(NA, ncats - 1, ncats - 1)
    namew = names(phat)
    dimnames(matw) = list(namew[-length(namew)], namew[-1])
    for (i1 in 1:(ncats - 1)) {
      for (i2 in 2:ncats) {
        tempw = phat[i1] - phat[i2] + abs(stats::qnorm((1 - conf.level)/(2 * ncatsC2))) * c(-1, 1) * sqrt(((phat[i1] + phat[i2]) - ((phat[i1] - phat[i2])^2))/n)
        tempw = round(tempw, 3)
        matw[i1, i2 - 1] = ifelse((i1 < i2), paste("(", tempw[1], ",", tempw[2], ")", sep = ""), " ")
        if ((0 <= tempw[1] | 0 >= tempw[2]) & (i1 < i2))
          matw[i1, i2 - 1] = paste(matw[i1, i2 - 1], "*", sep = "")
      }
    }
    ci_diff <- matw
    cat(paste(conf.pc, "%", sep = ""), "CIs for differences in true proportions (rowname-colname)", "\n", "(adjusted for", ncatsC2, "multiple comparisons)", "\n")
    print(matw, quote = FALSE)
  }
  list(CIs = CIs[, 1:3], ci_diff = ci_diff)
}
