---
title: "Designing a fast PDF text searching algorithm"
collection: pubs
category: posts
permalink: /pub/2026-07-28-doc-search
excerpt: 'A few weeks ago I wondered if I could make a custom, fast PDF text searching algorithm from scratch, using only my existing knowledge. This is the result.'
date: 2026-07-28
lang: en
---

A few weeks ago I wondered if I could make a custom, fast PDF text searching algorithm from scratch, using only my existing knowledge. [This](https://github.com/XabiF/fast-doc-search-poc){:target="_blank"} is the result.

- [Design](#design)
- ["Scribble-search" with lookup tables](#scribble-search-with-lookup-tables)
- [The art of indexing](#the-art-of-indexing)
  - [Text massaging](#text-massaging)
  - [It’s just a map](#its-just-a-map)
  - [Overall procedure](#overall-procedure)
- [Crafting binary files](#crafting-binary-files)
  - [Keeping everything fixed](#keeping-everything-fixed)
  - [Jumping element by element](#jumping-element-by-element)
  - [The kernel deals with it](#the-kernel-deals-with-it)
- [Bringing the PoC to life](#bringing-the-poc-to-life)
  - [Optimizations and terminal graphics](#optimizations-and-terminal-graphics)
  - [Blink and you miss it](#blink-and-you-miss-it)
  - [The PDF bottleneck](#the-pdf-bottleneck)
- [Concluding remarks](#concluding-remarks)

## Design

In order to keep a clear goal, I designed and coded this Proof-of-Concept (PoC) under the following design choices:

- Search logic must be as fast as possible
- The preprocessing/indexing step may be made slower, as it will not be executed very frequently (only if new PDFs were to be added to the collection)
- Temporary memory/storage is not a burden as long as it doesn't go beyond "acceptable" sizes (for instance, dozens of GB of preprocessed data for just a few PDF documents might be too much!)
- The PDF text may be massaged into simpler yet still human-readable text, since many elements of written text are irrelevant for content-searching purposes (like dots, commas, tildes, letter casing and so on)
- The PoC performance will be tested with my personal PDF library, which contains about ~700 books and scientific papers, roughly ~4GB of data in PDF format
- The PoC design must be as simple as possible, given the already stated principles (in other words, no LLM/RAG aid or overly complicated code logic)

The first two design goals go nicely together, since

In other words, it's convenient to move as much processing as possible to the preprocessing step (as a consequence, the searching step will be lighter), while avoiding an excessive amount of preprocessed data: a time vs. memory trade-off. 

## "Scribble-search" with lookup tables

I'm in the process of reverse-engineering the Nintendo DS game [**Super Scribblenauts**](https://github.com/XorTroll/super-scribblenauts-re){:target="_blank"}. For those unaware of the Scribblenauts saga, the common gist of the games is that you have a magical notebook which you can use to create nearly any object/live being you can imagine. *Super Scribblenauts* (the second game in the saga) and later saga entries also support adjectives as modifiers! This opens the door for infinitely many creative ideas for beating game levels. Just take a look at the game release trailer:

<div style="position: relative; width: 100%; padding-bottom: 56.25%">
<iframe src="https://youtube.com/embed/_udPpJgYiVA" 
        frameborder="0" allowfullscreen
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
        style="position: absolute; width: 100%; height: 100%;">
</iframe>
</div>

It is a rather slow-paced project, but I've already uncovered interesting aspects about how objects and adjectives are utilized in the game. The game uses several lookup tables to quickly find objects when the player types an object/adjective name. There are roughly ~5000 unique objects (not counting synonyms pointing to the same underlying object), so they had to come up with a somewhat fast search technique to make the search time feel as unnoticeable as possible to the player.

For this purpose, the game has several dedicated object and adjective lookup tables to be searched in order to find the object/adjective data. The interesting part about them is that they begin with a two-character 32-bit integer matrix/2D array, whose entries contain the location of word entries beginning with a given pair of characters.

Say you want to find the lookup table entry for the object "TOILET" (the game uses uppercase letters). Instead of having to traverse the lookup table entries one by one until you find the entry named "TOILET" (a naive and probably costly searching procedure), you just go to the matrix entry corresponding to the characters "TO", read the stored 32-bit value there (which consists of the position/offset of the lookup table file where all the words starting with "TO" are located) and begin your search there. By utilizing some extra initial space to store redundant information as an offset matrix, the search can be made significantly faster.

Inspired by this approach, I decided to go a step further (since our target data is orders of magnitude larger than the object/adjective data in *Super Scribblenauts*) and considered to make use of a three-character matrix (well, I guess you could call it a tensor) when storing the preprocessed data generated by this PoC.

## The art of indexing

The idea of preprocessing the words in the input text, also known as indexing, was on my mind from the very start of this experiment. Without any kind of preprocessing steps, the experiment would essentially boil down to reading the documents character by character and keep track of any matches... and we can certainly do better than that!

### Text massaging

Let's remove as many irrelevant elements from the text as possible. First of all, letter casing makes no difference, so all text can be transformed into lower-case characters. In fact, I found it easier to define a whitelist of allowed characters and filter everything else found when scanning the document text character by character. The allowed characters are lower-case `a`/`z`, numbers `0`/`9`, as well as special characters `-`, `:`, `.`, `/`, `\` and `*`.

All these special characters (except for `*`) are only allowed if they are found in the middle of words (they are only filtered if the previous/next character is also a space or another special character). This, among other things, prevents URLs from being awkwardly split (`https://archive.org` would be otherwise recognized as three separate words `https`, `archive` and `org`) while still skipping unnecessary punctuation marks, like commas or dots after words.

The character `*` is a doubly-special *pseudo-character* indicating a null/empty character, due to the lookup-table mechanism implicitly requiring at least three characters in a valid word. For example, the word `a` is stored as `a**` in the lookup table, while the extra characters are intentionally ignored when showing any found results. This trick was essentially introduced in order to avoid not-that-human-readable sentences when displaying the preprocessed text (otherwise, for example, the sentence "a horn of plenty" would just be "horn plenty" since the words `a` and `of` would’ve been ignored). Human-readability of the resulting search results is a design choice, after all.

### It’s just a map

Formally speaking, indexing is a matter of splitting text into unique chunks of letters and mapping each unique chunk to some unique numerical value. Modern text indexings used in language models are far beyond the scope of this work, and again, I wanted to keep this as a simple experiment.

As a naive indexing concept, I decided to simply map each unique preprocessed word to an incrementing index value: the first identified word is assigned index 0, the next one gets assigned index 1, and so on. Running preliminary tests with a few dozens of PDFs I noticed that the total amount of words I was finding was around ~30000, so I assumed that a 32-bit index would be more than enough even if the document database were to be several times larger. This way, arbitrary-sized words are mapped into a 4-byte, 32-bit index.

> In fact, the choice of integer sizes is key to optimize the design. Every used bit of space must have a purpose if we want to craft a well-suited design! For instance, if we were to have an integer which will always be bounded between 0 and 100, there is no point on using more than a byte to store it, since a byte already provides us with 256 unique values. These little space optimizations become specially relevant if problem is scaled: if we naively chose to use a 32-bit integer (4 bytes), we would be using three times more space!

### Overall procedure

Putting everything together, we have an indexing procedure to apply for every PDF document in our library. Each PDF is read word by word, and each unique word is mapped into a unique index.

Through this procedure, we end up with two relevant data objects: the indexed PDF contents for each document, which are now a chain of 32-bit integers (word after word) per document, and the dictionary/map that converts between words and indices. How shall we keep this data stored?

## Crafting binary files

Preprocessed data must be saved somewhere, so that it may be accessed as swiftly as possible when a search is performed. Luckily, I have some (humble) experience playing around with compact and fast-to-navigate binary files, since I've come across various types of file formats when reverse-engineering and playing around with various Nintendo systems and games.

The concept of a binary file is rather simple: they are nothing more than a sequence of bytes along with a scheme to interpret those bytes as data. Given four bytes, you may read them as four unsigned integers between 0 and 255, as four signed integers between -128 and 127, as two unsigned integers between 0 and 65535, and all the other possible combinations of data types. Designing a binary format is choosing what information is being encoded in which bytes, and thus, what representation to use when reading or writing them. We also have to consider the placement of the data, since different schemes can lead to very fast or very slow reading times, as I will explain in next sections.

For this reason, I followed two design choices for the preprocessed data files: the combination of fixed-size sections and jump offsets, and linked-list-inspired data insertion (although this last one was not really advantageous in the final prototype). The design of these binary files is explicitly explained in [this PoC repository](https://github.com/XabiF/fast-doc-search-poc){:target="_blank"} and in the code itself, but I'd like to share some intuition behind them.

### Keeping everything fixed

Imagine we want to store a list of words in a binary file. We have to somehow deal with the fact that different words will likely have different lengths, so how can we do it?

One solution is to store each word one after another, but putting a final byte indicating that the word has ended. In fact, this is how strings are internally encoded in memory in languages like C or C++, and how `strlen`, `printf` and many other functions can tell when a given string ends (otherwise they would keep endlessly reading byte after byte in memory and interpreting them all as characters). This (marginally) increases the data size by storing an extra byte for each word, but it allows us to identify where each word ends and the next one starts.

Equivalently, we could store the string length as a fixed integer (say 32-bit) prior to the word itself, so by reading the length first we already know beforehand how many characters we will need to read next. These two schemes are conceptually quite similar, yet they involve different trade-offs when you look at them closely. Knowing the full length allows you to read the entire string in bulk instead of byte-by-byte or arbitrary-sized-bulk reads, but at the same time it requires more than a single byte of extra space: another trade-off to take into account.

Consider now that we intend to frequently jump to specific words. In order to jump to the `n`-th word in the list, we cannot reliably predict the offset where the word will be located, as it depends on the different lengths of all previous words... unless we read the binary file word by word, keeping track of how many words have we come across, until we get there. This, as you may guess, can be prohibitely slow for long word lists.

An alternative option is to use fixed-size byte blocks for each word. If, for instance, we know beforehand that no word will ever have more than 50 characters (these kinds of bounds are usually reasonable to estimate in specific use-cases) we can store each word using a chunk of 50 bytes, filling the remaining empty bytes with some unique byte value that corresponds to no valid character (typically the extremes `0` or `255` are used). This scheme will likely waste more space than other simpler ones, but it allows us to very quickly navigate to the `n`-th word, since we know it is always located at the `50*n`-th byte. For this very reason, fixed-size sections are very common in binary file design.

Well, which one is the best option then? Long story short, this is yet another trade-off to consider. Depending on the use-case goals, one layout or another ought to be chosen. If you don't intend to perform these kinds of lookups, and care more about keeping the binary file as small as it can be, then the first option is more appropriate.

For this PoC, I relied on the first option to store words in the word-to-index mapping file. Since the three-character offset matrix already simplifies the procedure of searching through the map, this scheme is more than enough. In places like lists of indexed words, considering that word indices are always 4 bytes long, I can directly make use of the quick navigation that the second option described here enables. Again, the precise binary file layouts are explained in [this PoC repository](https://github.com/XabiF/fast-doc-search-poc){:target="_blank"} if you wish to dive deeper.

### Jumping element by element

A linked list is a simple data structure concept widely used in programming. Simply put, it's a list where each list element points to the next one by storing information somewhere in the element itself.

For example, let's consider a linked list of variable-length strings. Using C-like pseudocode, this is an example structure design for a list element:

```cpp
struct StringListElement {
    u32 next_element_relative_position; // Or 0 if there is no next element (end of the list)
    u32 string_length;
    char string[string_length]; // (a char is the same size as a byte)
}
```

On each element, the first 32-bit integer points to where the next element starts. If you imagine the entire linked list as a contiguous list of elements in memory, one after each other, this means that `next_element_relative_position` bytes after the start of the current element is where the next element begins. This means that, without having to read any other contents of a list element, we can quickly jump element after element by just reading these relative offsets until reaching whatever element we are looking for. For instance, if we wish to find the end of the list, we just have to jump from the start of the list, element by element, until we find the element with no next element information in it.

This is a notoriously simple example (in fact, just with the string and its length you could already easily find out where the next element is, as hinted in the previous section), but for more complicated data to be stored on the list, this system provides a really easy way to quickly navigate a list.

### The kernel deals with it

This project was the first time I've relied on the Linux kernel to perform any file I/O.

The kernel provides two utilities (`mmap` and `munmap`) to map/unmap memory. Instead of having to manually call `read`/`write`/`seek` functions to move and operate through the file, the kernel takes care of those operations internally, and it simply provides me with a pointer to the file data as if it were any other memory in the program. This is not only cleaner but also faster due to all memory reading and mapping being done at the kernel level directly.

While I did not make any proper performance comparisons back when testing early design ideas on the PoC, I recall noticing some qualitative speedup after switching from regular file I/O to `mmap` magic. Since I switched I/O strategies back when I was testing over a smaller PDF database, I can only hypothesize that the performance gain will be even higher when working over my entire PDF library.

## Bringing the PoC to life

### Optimizations and terminal graphics

While I coded the very early testing in Python, since the very start I wanted to settle on C++ for a nicely working PoC, mainly due to speed and performance concerns. After all, no Python code will ever beat, maybe not even come close to an equivalent C++ code compiled with `-O3` optimization and other cleverly chosen compiler flags.

I also wanted to make a **dynamic** search tool from the beginning: some nice UI where the search result refreshes every time your search query changes (that is, every time you type or delete a character). I was really hoping that search times would be fast enough to make it seem instantaneous. Since making a GUI (graphical UI) can be quite time-consuming, I decided to introduce myself to [ncurses](https://invisible-island.net/ncurses/){:target="_blank"} for the first time to (learn to) make a simple TUI (terminal UI) interface.

### Blink and you miss it

So, having this amount of care put into optimizing the PoC design, how well does the final prototype perform?

As a reminder, I intend to study the performance of this PoC on my personal PDF library, which consists of roughly ~700 PDFs of a combined ~4GB size.

The indexing routine takes roughly ~4-5min to complete, and produces ~600k words. The resulting files are a ~10MB word table file and a ~100MB document table file.

<div style="text-align: center;">
<img src="/images/pubs/doc-search/docsearch-index.png" alt="drawing" width="90%"/>
</div>

Well, what about the word search? See it for yourself:

<div style="text-align: center;">
<video width="90%" autoplay loop muted controls>
  <source src="/images/pubs/doc-search/docsearch.mp4" type="video/mp4"/>
</video>
</div>

> Minor note: I'm using a slightly reduced version of my personal library on this video, more like ~3GB in size, but the search times are pretty much the same than with the full library.

Searching is indeed instantaneous for most search queries, although this clearly depends on the word frequency in the database. Ultra-frequent words such as `a`, `of`, `and` or `the` take noticeable times close to a second, which is nonetheless impressive considering the millions of found ocurrences in the entire database. Needless to say, the code could be easily adapted to only search and return the first `N` occurrences, in which case this would no longer be a problem.

I find particularly impressive that, as a result of the chosen indexing design, the algorithm is stupid fast at finding out if a word is not present in any of the indexed PDFs in the entire database, taking merely tens of microseconds (wow) thanks to the fast lookup in the word table file design.

I was quite tempted to make a brief study on the relationship between word frecuency and search time, and I was somewhat surprised to find it nicely follows a linear trend:

<div style="text-align: center;">
<img src="/images/pubs/doc-search/linear-regression.png" alt="drawing" width="80%"/>
</div>

`y = 6.077165447367483e-07 x + 0.010739720187252819 (R^2 = 0.99662)`

Additionally, note that the searching routine takes some time looking up words nearby each occurrence in order to print the search results in a user-friendly way. It is worth mentioning that search times notoriously improve if this lookup is removed, to the point where the search time for `the` (one of the worst ones) drops from ~0.75s to ~0.03s. These sorts of minor tweaks on the algorithm code might have huge effects on performance if it were adapted to a particular use-case!

### The PDF bottleneck

All testing so far was done over PDF files, yet PDF text extraction is a highly nontrivial procedure. In fact, it took me quite some time to find a good C++ library for this purpose (until I found [poppler](https://poppler.freedesktop.org/){:target="_blank"}). PDF files are a rather complicated format, with text placed in different parts of a page (and with tons of subtleties I don't even know of). After all, how do you map, for example, a multi-column academic paper PDF into a regular text file, which is nothing more than a chain of words with no explicit notion of a layout or positioning?

If this work were applied to regular text files, like code or Markdown files, the indexing step would be drastically faster. In fact, if I preprocess PDF files as text files externally, and then run the indexing over the ~160MB of plaintext files, it takes a mere 16s to preprocess compared to the ~5min of PDF file indexing.

## Concluding remarks

Could this algorithm be improved? Undoubtedly so.

After all, the followed design choices made this PoC rather poorly suited for many use-cases where LLMs strive. The indexing I employed is useless at reflecting similarities in words (not in letter proximity nor in semantical closeness) while well-known NLP word embeddings, paying the cost of using hundred- or thousand-dimensional vectors for each token instead of a mere 32-bit integer, are ideal for those purposes. In fact, this indexing generates a lot of garbage words (some examples: `an/aps-135`, `uniform0.2`, `111303022013102321`, `li:..tan`, `x3b3`) which are not meaningful in any way. I'm pretty sure a more careful preprocessing and string filtering code could likely reduce the total word count and further improve search times.

As a fun sidenote, I did make a small prototype where I tried to preprocess and store every single word appearance as part of the indexing procedure. After all, having all ocurrences already pre-computed as a colossal dictionary sounded like an interesing approach: it reduces the entire searching problem to a fast custom-dictionary lookup problem. However, the resulting file was growing so damn quickly as the indexing code was running (getting fast into dozens-of-GB territory) that I inmediately abandoned the idea. Caching is a powerful technique (the kernel of device you're reading this on is relying on its own memory caching shenanigans right now), but abusing it puts too much burden on space/memory requirements. Remember the idea of time vs. space trade-offs? Both extremes turn out to be quite inefficient for their own reasons!

This really was a fun project to explore and play around with. After all, it is by spending time in these random experiments that you get to learn the subtleties of many complex topics (text preprocessing, space/time optimization, binary file design, fast lookup, I/O, and so on). I might get back to this experiment and try to implement some of these potential improvements in the future, who knows...

> No LLM aid was used to write this post, nor to design or code this PoC ;)
