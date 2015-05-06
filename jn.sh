#!/bin/bash
#########################################################################################
#
# NASCIMENTO    : 11 de junho de 2011
# AUTOR     	: Ielton Ferreira Carneiro Pinto
# DESCRICAO 	: Esse cria e atualiza a lista dos nerdcasts, tambem realiza comentarios
#
#########################################################################################

# CONFIG GLOBAIS
WSRC="lynx --source http://jovemnerd.com.br/feed/?cat=42";
#DEFINE LISTA LOCAL PARA LISTA
LIST="nerdcast.list";
#DEFINE LOCAL PARA LISTA TEMPORARIA
TLST="/tmp/nerdcast.tmp";


# VERIFICA SE O ARQUIVO DE LISTA FOI CRIADO. 

if [ ! -e nerdcast.list ];

then

# CASO NAO, ELE CRIA A LISTA DE TODOS OS LINKS PARA OS NERDCASTS

$WSRC | sed -n -e '/<comments>.*/d' -e '/<dc:creator>/d' -e '/<category>/d' -e '/<guid.*/d' -e '/<description>.*/d' -e '/<blockquote>/,/<\/item>/d' -e 's/\+0000//g' -e 's/\t//g' -e '/<title>Nerdcast [0-9]\{1,9\}/,+25p' | sed -e :a -e 's/<[^>]*>//g' -e '/^$/d' -e '/Nerdcast [0-9]\{1,9\}.*/{x;p;x;}' -e 's/&#8211;/-/g' -e 's/&#8220;/\“/g' -e 's/&#8221;/\”/g' -e 's/&#8230;/…/g' -e 's/&#215;/×/g' -e 's/&#8216;/\‘/g' -e 's/&#038;/\&/g' -e "s/&#8217;/\'/g" > $LIST;

fi

###################################################
# DEFINICAO DE FUNCOES
###################################################

# FUNCAO PARA ATUALIZAR LISTA

update()
{

# BAIXA LISTA TEMPORARIA
$WSRC | sed -n -e '/<comments>.*/d' -e '/<dc:creator>/d' -e '/<category>/d' -e '/<guid.*/d' -e '/<description>.*/d' -e '/<blockquote>/,/<\/item>/d' -e 's/\+0000//g' -e 's/\t//g' -e '/<title>Nerdcast [0-9]\{1,9\}/,+25p' | sed -e :a -e 's/<[^>]*>//g' -e '/^$/d' -e '/Nerdcast [0-9]\{1,9\}.*/{x;p;x;}' -e 's/&#8211;/-/g' -e 's/&#8220;/\“/g' -e 's/&#8221;/\”/g' -e 's/&#8230;/…/g' -e 's/&#215;/×/g' -e 's/&#8216;/\‘/g' -e 's/&#038;/\&/g' -e "s/&#8217;/\'/g" > $TLST;

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
cat nerdcast.list | sed -n '/http:\/\/jovemnerd\.com\.br\/nerdcast\//p' | grep $1 | cut -c34- | sed 's/\///g'
#cat nerdcast.list | grep $1
}

###############################
# FUNCAO PARA BAIXAR NERDCAST
###############################

get()
{
#cat nerdcast.list | sed -n '/http:\/\/jovemnerd\.com\.br\/nerdcast\//p' | grep 01 | cut -c34- | sed 's/\///g'
lynx -dump $1 | awk '/zip/{print $2}' | xargs wget -O /tmp/nerdcast_tmp.zip && unzip /tmp/nerdcast_tmp.zip -d nerdcasts/
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
    ecomment
URLNC=$LASTNC
    get

else
    echo "Sua lista já está com a última atualização disponível!";
fi
;;

comment)
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
    jn upgrade - Atualiza insistentemente e comenta assim que a lista esteja atualizada.
    jn search [N° NERDCAST][PALAVRA CHAVE]
    jn get [URL]
    Para mais informações:  jn --help"
;;

esac
