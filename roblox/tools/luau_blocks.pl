#!/usr/bin/perl
# Verificador de blocos Luau (não é um compilador): confere se cada function/if/do/
# repeat fecha com end/until e se parênteses, chaves e colchetes casam. Ignora
# comentários e strings (inclusive [[...]] e `...`). Útil porque não há Luau
# executável neste repositório; não pega erros de tipo nem de nome.
# Uso (Git Bash):
#   perl roblox/tools/luau_blocks.pl roblox/src/server/Main.server.luau
#   find roblox/src -name '*.luau' -print0 | xargs -0 perl roblox/tools/luau_blocks.pl | grep -v ': OK$'
# Cada arquivo sem problema imprime "arquivo: OK"; os problemas saem como
# "arquivo:linha: descrição". Sem saída fora dos OK = blocos fechados.
use strict; use warnings;
my %exprprev = map {$_=>1} ('=','(',',','{','[','return','and','or','not','==','~=','<','>','<=','>=','+','-','*','/','%','^','..','+=','-=','*=','/=','..=','#');
for my $f (@ARGV) {
  open my $fh, '<:raw', $f or die; local $/; my $s = <$fh>; close $fh;
  my @stack; my @par; my $line = 1; my $prev = ''; my $err = 0;
  pos($s) = 0;
  while (pos($s) < length $s) {
    if ($s =~ /\G\n/gc) { $line++; next }
    if ($s =~ /\G[ \t\r]+/gc) { next }
    if ($s =~ /\G--\[(=*)\[(.*?)\]\1\]/gcs) { $line += () = $2 =~ /\n/g; next }
    if ($s =~ /\G--[^\n]*/gc) { next }
    if ($s =~ /\G\[(=*)\[(.*?)\]\1\]/gcs) { $line += () = $2 =~ /\n/g; $prev='STR'; next }
    if ($s =~ /\G(["\x27`])/gc) { my $q=$1; my $p=pos($s); my $ok=0; while ($p < length $s) { my $c=substr($s,$p,1); if ($c eq "\\") { $p+=2; next } if ($c eq "\n") { last } $p++; if ($c eq $q) { $ok=1; last } } pos($s)=$p; if (!$ok) { print "$f:$line: unterminated string\n"; $err=1 } $prev="STR"; next }
    if ($s =~ /\G([A-Za-z_][A-Za-z0-9_]*)/gc) {
      my $t = $1;
      if ($t eq 'function' || $t eq 'do' || $t eq 'repeat') { push @stack, [$t,$line] }
      elsif ($t eq 'if') { if ($exprprev{$prev}) { push @stack, ['ifexpr',$line,scalar(@par)] ; pop @stack; } else { push @stack, ['if',$line] } }
      elsif ($t eq 'end') { my $o = pop @stack; if (!$o) { print "$f:$line: extra end\n"; $err=1 } elsif ($o->[0] eq 'repeat') { print "$f:$line: end closes repeat($o->[1])\n"; $err=1 } }
      elsif ($t eq 'until') { my $o = pop @stack; if (!$o || $o->[0] ne 'repeat') { print "$f:$line: until mismatch\n"; $err=1 } }
      $prev = $t; next;
    }
    if ($s =~ /\G(0x[0-9a-fA-F_]+|\d[\d_]*(?:\.\d*)?(?:[eE][-+]?\d+)?|\.\d+)/gc) { $prev='NUM'; next }
    if ($s =~ /\G(\.\.\.|\.\.=|\.\.|==|~=|<=|>=|\+=|-=|\*=|\/=|%=|\^=|::|->|\/\/|[-+*\/%^#<>=(){}\[\];:,.?&|])/gc) {
      my $t = $1;
      if ($t =~ /^[({\[]$/) { push @par, [$t,$line] }
      elsif ($t =~ /^[)}\]]$/) { my $o = pop @par; my %m=(')'=>'(','}'=>'{',']'=>'['); if (!$o || $o->[0] ne $m{$t}) { print "$f:$line: bracket mismatch $t (open ".($o?"$o->[0]\@$o->[1]":'none').")\n"; $err=1 } }
      $prev = $t; next;
    }
    $s =~ /\G(.)/gcs; print "$f:$line: odd char ".sprintf('%02x',ord $1)."\n"; $err=1;
  }
  print "$f:$_->[1]: unclosed $_->[0]\n" for @stack;
  print "$f:$_->[1]: unclosed bracket $_->[0]\n" for @par;
  print "$f: OK\n" if !@stack && !@par && !$err;
}
