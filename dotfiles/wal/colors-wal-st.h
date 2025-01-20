const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#071618", /* black   */
  [1] = "#169972", /* red     */
  [2] = "#553190", /* green   */
  [3] = "#2D628A", /* yellow  */
  [4] = "#5B5B9F", /* blue    */
  [5] = "#A66CBB", /* magenta */
  [6] = "#239F9A", /* cyan    */
  [7] = "#93e0d0", /* white   */

  /* 8 bright colors */
  [8]  = "#669c91",  /* black   */
  [9]  = "#169972",  /* red     */
  [10] = "#553190", /* green   */
  [11] = "#2D628A", /* yellow  */
  [12] = "#5B5B9F", /* blue    */
  [13] = "#A66CBB", /* magenta */
  [14] = "#239F9A", /* cyan    */
  [15] = "#93e0d0", /* white   */

  /* special colors */
  [256] = "#071618", /* background */
  [257] = "#93e0d0", /* foreground */
  [258] = "#93e0d0",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
