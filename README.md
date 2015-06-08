# roboconfucius
Robot Confucius generates random literary Chinese with bigram frequencies of training text.

## Usage
```
 $ perl roboconfucius.pl -i INPUT -t 1 -m 25 -f OUT1 -g OUT2 -p
```
## Options
* `-i FILE` Input file, UTF-8 encoded
* `-t INT` Number of sentence generation cycles (default 1)
* `-m INT` Maximum sentence length (default 25)
* `-f FILE` Output tab-separated table of character counts (optional)
* `-g FILE` Output tab-separated table of bigram counts (optional)
* `-p` Keep punctuation in bigrams (default: no)

## Principle
[**n**-grams](http://en.wikipedia.org/wiki/N-gram) are strings of **n** characters from an alphabet. This can be text, phonetic syllables, or even DNA sequences (where they are better known as **k**-mers). Calculating the **n**-gram frequency for a given **n** is a convenient way of estimating the information content of a text. The **n**-gram approach has been applied to large-scale text corpora by the [Google Books project](https://books.google.com/ngrams).

A fun application of n-grams is the generation of random text. For example, with bigrams (2-grams), a random word is chosen with a probability proportional to its frequency in the corpus (training text). The next word is chosen randomly, in proportion to the frequency of the (word1, word2) bigrams. The third word is chosen in the same way, and so on. 

Robot Confucius generates random Chinese text from bigram frequencies. In principle it will work with any text that is Unicode (UTF-8) encoded. However, since the units are individual characters, it works best with Chinese (with English, for example, you would want to index words, not letters).

Literary Chinese seems well-suited for random text generation, because it is terse and formulaic. 

## Texts
Get text for input from sources such as [Project Gutenberg](https://www.gutenberg.org/) or the [Chinese Text Project](http://ctext.org/). For licensing reasons I am not providing copies of texts here.

Input files should be plain text, without non-Chinese characters (punctuation, numbers, and spaces are automatically stripped), and without chapter/section headings. If you use the Project Gutenberg texts, that means you should remove the header and license lines from the file.

## Example output

### Robot Confucius 
Trained on the **Analects**
> 使門鞠躬自行君賜也而求諸子曰魯師摯適仲之不樂樂然善不己知德之達伯玉邦君子路使陽之天何冉有功公之本立未足

### Robot Zhuangzi
Trained on the Inner Chapters of the **Zhuangzi**
> 者水於連乎塵埃之謂以異乎治老聃曰凡事其然疲役人謂成則速毀首以相與魚見之瞻明物一唯舜曰奚來明日中繩墨之息
