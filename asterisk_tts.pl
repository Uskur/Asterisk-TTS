#!/usr/bin/perl
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Burak USGURLU <burak@uskur.com.tr>
# Çevirilmiş Asterisk dil dosyasındaki metinleri Google TTS servisini kullanarak sese çevirir.
# Türkçe Asterisk ses dosyaları üretir.
#
# Ubuntu için kurulu olmayı gerektiren paketler:
# sudo apt-get install perl wget mp3wrap sox libsox-fmt-all
# 

use strict;
use warnings;
#filename to read lines from
my $file="core-sounds-tr.txt";
#language to read the files in
my $language="tr";
#necessary subdirectories
my @directories=("dictate","digits","letters","phonetic","silence","followme");

#create the necessary directories
foreach my $directory (@directories){
	mkdir($directory);
}

#processing the file
open my $info, $file or die "Could not open $file: $!";
my $count=0;
while( my $line = <$info>)  {
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	#if the line is not commented out or empty
	if(substr($line, 0, 1) ne ";" && $line ne ""){
		my @parts = split(':',$line,2);
		print "'$parts[0]'";
		#google tts accepts 100 characters
		#so we split the string and then join the mp3
		if(length($parts[1]) > 100){
			my $stringCount=0;
			my @strings=("");
			my @words=split(' ',$parts[1]);
			foreach my $word (@words){
				my $temp=$strings[$stringCount]." $word";
				if(length($temp) < 100 ){ $strings[$stringCount].=" $word";}
				else{
					system("wget -q -U Mozilla -O $parts[0]-$stringCount.mp3 \"http://translate.google.com/translate_tts?ie=UTF-8&tl=$language&q=$strings[$stringCount]\"");
					$stringCount++;
					push(@strings,"$word");
				}
			}
			system("wget -q -U Mozilla -O $parts[0]-$stringCount.mp3 \"http://translate.google.com/translate_tts?ie=UTF-8&tl=$language&q=$strings[$stringCount]\"");
			print " [$stringCount parts]";
			#use mp3wrap to merge mp3 files
			system("mp3wrap $parts[0].mp3 $parts[0]-*.mp3");
			#delete the mp3 parts
			unlink glob "$parts[0]-*.mp3";
			#mp3wrap appends MP3WRAP to the filename, we don't need it
			rename("$parts[0]_MP3WRAP.mp3","$parts[0].mp3");
			print " [parts merged]";
		}
		else{
			system("wget -q -U Mozilla -O $parts[0].mp3 \"http://translate.google.com/translate_tts?ie=UTF-8&tl=$language&q=$parts[1]\"");
			print " [1 part]";
		}
		#convert the mp3 to gsm files that asteriks use
		system("sox $parts[0].mp3 -r 8000 -c 1 $parts[0].gsm resample -ql");
		print " [mp3 converted]\n";
		#we can add more sound file conversions here
		$count++;
	}
}
close $info;
print "\n\n$count lines read to sound files\n";
exit 0;

