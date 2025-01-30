const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#060D13", /* black   */
  [1] = "#837B70", /* red     */
  [2] = "#076B89", /* green   */
  [3] = "#0E9DA2", /* yellow  */
  [4] = "#2CCACD", /* blue    */
  [5] = "#68F4F5", /* magenta */
  [6] = "#B1A499", /* cyan    */
  [7] = "#c5f5f5", /* white   */

  /* 8 bright colors */
  [8]  = "#89abab",  /* black   */
  [9]  = "#837B70",  /* red     */
  [10] = "#076B89", /* green   */
  [11] = "#0E9DA2", /* yellow  */
  [12] = "#2CCACD", /* blue    */
  [13] = "#68F4F5", /* magenta */
  [14] = "#B1A499", /* cyan    */
  [15] = "#c5f5f5", /* white   */

  /* special colors */
  [256] = "#060D13", /* background */
  [257] = "#c5f5f5", /* foreground */
  [258] = "#c5f5f5",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
