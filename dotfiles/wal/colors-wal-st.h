const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0D0E0E", /* black   */
  [1] = "#4E7A91", /* red     */
  [2] = "#3789A8", /* green   */
  [3] = "#5998A9", /* yellow  */
  [4] = "#67AEC7", /* blue    */
  [5] = "#9DA9A3", /* magenta */
  [6] = "#D9D1B9", /* cyan    */
  [7] = "#cad9db", /* white   */

  /* 8 bright colors */
  [8]  = "#8d9799",  /* black   */
  [9]  = "#4E7A91",  /* red     */
  [10] = "#3789A8", /* green   */
  [11] = "#5998A9", /* yellow  */
  [12] = "#67AEC7", /* blue    */
  [13] = "#9DA9A3", /* magenta */
  [14] = "#D9D1B9", /* cyan    */
  [15] = "#cad9db", /* white   */

  /* special colors */
  [256] = "#0D0E0E", /* background */
  [257] = "#cad9db", /* foreground */
  [258] = "#cad9db",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
