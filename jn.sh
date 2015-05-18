#!/bin/bash
###################################################################################
#
# NASCIMENTO    : 11 de junho de 2011
# AUTOR     	: Ielton Ferreira Carneiro Pinto
# DESCRICAO 	: Esse cria e atualiza a lista dos nerdcasts, tambem realiza 
#		  comentarios
#
###################################################################################

# CONFIG GLOBAIS
WSRC="lynx --source http://jovemnerd.com.br/feed/?cat=42";
# DIRETORIO DOS NERDCASTS
NDIR=$HOME"/nerdcasts";
# DEFINE LISTA LOCAL PARA LISTA
LIST="nerdcast.list";
# DEFINE LOCAL PARA LISTA TEMPORARIA
TLST="/tmp/nerdcast.tmp";
if [ ! -d $NDIR ];
then
mkdir $NDIR;
fi

# VERIFICA SE O ARQUIVO DE LISTA FOI CRIADO. 
if [ ! -e nerdcast.list ];

then
# CASO NAO, ELE CRIA A LISTA DE TODOS OS LINKS PARA OS NERDCASTS
$WSRC | sed -n -e '/<title>Nerdcast .*/p;/<link>http:\/\/jovemnerd.com.br\/nerdcast\//p;/<pubDate>/p;/<description>/p;/<itunes:duration>/p' | sed -e 's/<itunes:duration>/Duração: /g;s/<\!\[CDATA\[//g;s/<[^>]*>//g;1d;s/\t//g;s/\+0000//g;/Nerdcast .*/{x;p;x;}' -e 's/&#8211;/-/g' -e 's/&#8220;/\“/g' -e 's/&#8221;/\”/g' -e 's/&#8230;/…/g' -e 's/&#215;/×/g' -e 's/&#8216;/\‘/g' -e 's/&#038;/\&/g' -e "s/&#8217;/\'/g" -e 's/\[…\]\]\]>/…/g' | sed -e '1d' > $LIST;

fi

##########################
#  DEFINICAO DE FUNCOES  #
##########################

# FUNCAO PARA ATUALIZAR LISTA
update()
{
# BAIXA LISTA TEMPORARIA
$WSRC |  sed -n -e '/<title>Nerdcast .*/p;/<link>http:\/\/jovemnerd.com.br\/nerdcast\//p;/<pubDate>/p;/<description>/p;/<itunes:duration>/p' | sed -e 's/<itunes:duration>/Duração: /g;s/<\!\[CDATA\[//g;s/<[^>]*>//g;1d;s/\t//g;s/\+0000//g;/Nerdcast .*/{x;p;x;}' -e 's/&#8211;/-/g' -e 's/&#8220;/\“/g' -e 's/&#8221;/\”/g' -e 's/&#8230;/…/g' -e 's/&#215;/×/g' -e 's/&#8216;/\‘/g' -e 's/&#038;/\&/g' -e "s/&#8217;/\'/g" -e 's/\[…\]\]\]>/…/g' | sed -e '1d' > $TLST;

# VERIFICA A DIFERENCAO ENTRE A LISTA LOCAL E A LISTA DO SERVIDOR
LASTNC=$(diff nerdcast.list /tmp/nerdcast.tmp | sed -n '2p' | cut -c 3-);

# VERIFICA SE $LASTNC TEM ALGUM VALOR ATRIBUIDO
if [ ! -z "$LASTNC" ];

then
# SINCRONIZA A LISTA TEMPORARIA COM A LOCAL
cat /tmp/nerdcast.tmp > nerdcast.list && printf "Lista atualizada! \nÚltimo EP: $LASTNC \n";

else
# ENVIA UMA MENSAGEM, CASO NENHUMA ATUALIZACAO SEJA ENCONTRADA
    echo "Os arquivos já estavam atualizados, nenhuma atualização realizada!";
fi
}

################################
# FUNCAO PARA PROCURAR NERDCAST
################################
search()
{
if ! cat $LIST | sed -n -e '/http:\/\/jovemnerd\.com\.br\/nerdcast\//!d;p' | sed  's/.*\/nerdcast\///g; s/\///g; s/^nerdcast-//g' | grep -i $1;

then
echo "Não achei nada :(";

fi

}

####################################
# FUNCAO QUE MOSTRA DETALHES DO NC
####################################
show()
{
if echo $1 | egrep '^[0-9]+$' > /dev/null;
then
cat $LIST | sed -n -e "/Nerdcast $1.* -/,+5p";

else
cat $LIST | sed -n -e "/Nerdcast [0-9]\{1,9\}.* -.*$1.*/I,+5p";

fi
}

###############################
# FUNCAO PARA BAIXAR NERDCAST
###############################
get()
{
URL=$(cat nerdcast.list | grep $1);
if [ -z $URL ];
echo "Baixando de: $URL";
then
lynx -dump $URL | awk '/\.mp3/{print $2}' | head -n1 | xargs wget -P $NDIR
else
echo "Use a funcao 'search' para localizar o titulo do nerdcast!";
fi
}

case $1 in
# ESSA OPCAO SOMENTE ATUALIZA A LISTA
update)
update
;;
# ESSA OPCAO ATUALIZA INSISTENTEMENTE A LISTA E COMENTA QUANDO ESTIVER ATUALIZADA
upgrade)

update
i=1
while [ -z $LASTNC ];
do
update
echo "Tentativa de atualização: $i"; date "+%H:%M:%S - %d/%m/%Y - %A" | tee log.txt
i=$((i+1));
done

if [ ! -z $LASTNC ];
then
URLNC=$LASTNC
    get

else
    echo "Sua lista já está com a última atualização disponível!";
fi
;;

show)
show $2;
;;

search)
search $2;
;;

get)
get $2;
;;
*)
echo "Uso:
    jn update  - Atualiza a lista de nerdcasts.
    jn upgrade - Tenta insistentemente atualizar lista.
    jn search [N° NERDCAST][PALAVRA CHAVE]
    jn show [N° NERDCAST][PALAVRA CHAVE]
    jn get [URL]
    Para mais informações:  jn --help"
;;
esac
