#!/usr/bin/perl -w

use strict;

return {
# CFG//@CORPORA
#
# id, adatbázisfájl, lemmafreqfájl, leírás, méret (millió szó), freqth
# XXX még db_noverb is van/lesz egyszer! :)
#
# az id-k szíveskedjenek különbözõk lenni! :)
#  * .gz fájlokat is lehet ide írni szükség esetén!
#  * több fájlt is meg lehet egy korpuszként adni, de akkor azok a fájlok
#    egységesen vagy tömörítettek vagy tömörítetlenek legyenek!
'CORPORA' => [

  { id => 'hnc',
    db => 'hnc.mazsoladb.gz', # demo: verbs beginning with 'n'
    dbfreq => 'hnc.fq', # XXX empty...
    gloss => 'Magyar Nemzeti Szövegtár',
    size => '0',
    freqth => 2 },

],


# CFG//$LOAD_AVG_TH                      
'LOAD_AVG_TH' => 3, # efölött a load fölött nem fogadunk kérést!


# CFG//$CHARSET
'CHARSET' => 'iso-8859-2', # ok: 'hnc' and 'int' -- not ok: 'ddt' and 'tlt'


# CFG//$NOVERBMSG
'NOVERBMSG' => '', # 1 ha kell, '' ha nem kell


# CFG//$EXAMPLES
'EXAMPLES' => q(

<!-- VAB -->

Magyar Nemzeti Szövegtár:
<a href="#" onClick="clearAll();
set( 'stem', 'hány' );
set( 'case1', '-t' );
setR( 'stat', 'stat1' )
">hány -t</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'hány' );
set( 'case1', '-re' );
setR( 'stat', 'stat1' )
">hány -re</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'esik' );
set( 'case1', '-be' );
setR( 'stat', 'stat1' )
">esik -be</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'fakaszt' );
set( 'case1', '-t' );
setR( 'stat', 'stat1' )
">fakaszt -t</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'kerül' );
set( 'case1', 'alá' );
setR( 'stat', 'stat1' )
">vmi alá kerül</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'vesz' );
set( 'case1', 'alá' );
setR( 'stat', 'stat1' )
">vmi alá vesz</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'kever' );
set( 'case1', '-t' );
setR( 'stat', 'stat1' )
">kever -t</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'kavar' );
set( 'case1', '-t' );
setR( 'stat', 'stat1' )
">kavar -t</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'fest' );
set( 'case1', '-t' );
setR( 'stat', 'stat1' )
">fest -t</a>,

<br/>

<a href="#" onClick="clearAll();
set( 'stem', 'fest' );
set( 'case1', '-t' );
set( 'case2', '-re' );
setR( 'stat', 'stat2' )
">fest -t -re</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'ad' );
set( 'case1', '-t' );
set( 'lemma1', 'hang' );
set( 'case2', '-nak' );
setR( 'stat', 'stat2' )
">hangot ad -nek</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'vesz' );
set( 'case1', '-t' );
set( 'lemma1', 'rész' );
set( 'case2', '-ben' );
setR( 'stat', 'stat2' )
">részt vesz -ben</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'kerül' );
set( 'case1', '-re' );
set( 'case2', 'alany' );
set( 'lemma2', 'sor' );
setR( 'stat', 'stat1' );
">sor kerül -re</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'kerül' );
set( 'case1', '-re' );
set( 'case2', 'alany' );
setC( 'lemma2not', true ); set( 'lemma2', 'sor' );
setR( 'stat', 'stat1' )
">kerül -re (de nem sor!)</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'forog' );
set( 'case1', '-ben' );
set( 'lemma1', 'veszély' );
set( 'case2', 'alany' );
setR( 'stat', 'stat2' )
">vmi veszélyben forog</a>

<br/>

<!-- VABD -->

Danish Dependency Treebank:
<a href="#" onClick="clearAll();
set( 'stem', 'have' );
set( 'case1', 'dobj' );
setR( 'stat', 'stat1' )
">have dobj</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'få' );
set( 'case1', 'dobj' );
setR( 'stat', 'stat1' )
">få dobj</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'være' );
set( 'case1', 'i' );
setR( 'stat', 'stat1' )
">være i</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'være' );
set( 'case1', 'på' );
setR( 'stat', 'stat1' )
">være på</a>,

<a href="#" onClick="clearAll();
set( 'case1', 'til' );
setR( 'stat', 'stat1' )
">til (without verb)</a>,

<a href="#" onClick="clearAll();
set( 'case1', 'ved' );
setR( 'stat', 'stat1' )
">ved (without verb)</a>

<br/>

<!-- VABS -->

Intera korpusz (szerb):
<a href="#" onClick="clearAll();
set( 'stem', 'imati' );
set( 'case1', 'ANYCASE' );
setR( 'stat', 'stat1' )
">imati ANYCASE</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'imati' );
set( 'case1', 'ANYCASE' );
set( 'lemma1', 'pravo' );
set( 'case2', 'na' );
setR( 'stat', 'stat2' )
">imati pravo na</a>

<br/>

<!-- VABNLFR -->

TLT korpusz (holland-francia párhuzamos):
<a href="#" onClick="clearAll();
set( 'stem', 'nl_maken\\\\+fr_faire' );
set( 'case1', 'nl_ACC' );
setR( 'stat', 'stat1' )
">nl_maken\+fr_faire nl_ACC</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'nl_maken\\\\+fr_faire' );
set( 'case1', 'fr_ACC' );
setR( 'stat', 'stat1' )
">nl_maken\+fr_faire fr_ACC</a>,

<a href="#" onClick="clearAll();
set( 'stem', 'nl_maken\\\\+fr_faire' );
set( 'case1', 'nl_ACC' );
set( 'lemma1', 'deel' );
set( 'case2', 'fr_ACC' );
set( 'lemma2', 'partie' );
setR( 'stat', 'statstem' )
">maken deel + faire partie</a>

)
};

