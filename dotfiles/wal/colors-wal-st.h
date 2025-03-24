const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#090e0a", /* black   */
  [1] = "#2F4C29", /* red     */
  [2] = "#336127", /* green   */
  [3] = "#525B2A", /* yellow  */
  [4] = "#3C4E44", /* blue    */
  [5] = "#556652", /* magenta */
  [6] = "#638C4A", /* cyan    */
  [7] = "#bdbca3", /* white   */

  /* 8 bright colors */
  [8]  = "#848372",  /* black   */
  [9]  = "#2F4C29",  /* red     */
  [10] = "#336127", /* green   */
  [11] = "#525B2A", /* yellow  */
  [12] = "#3C4E44", /* blue    */
  [13] = "#556652", /* magenta */
  [14] = "#638C4A", /* cyan    */
  [15] = "#bdbca3", /* white   */

  /* special colors */
  [256] = "#090e0a", /* background */
  [257] = "#bdbca3", /* foreground */
  [258] = "#bdbca3",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
