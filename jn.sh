#!/bin/bash
#########################################################################################
#
# NASCIMENTO    : 11 de junho de 2011
# AUTOR     	: Ielton Ferreira Carneiro Pinto
# DESCRICAO 	: Esse cria e atualiza a lista dos nerdcasts, tambem realiza comentarios
#
#########################################################################################

# VERIFICA SE O ARQUIVO DE LISTA FOI CRIADO. 

if [ ! -e nerdcast.list ];

then

# CASO NAO, ELE CRIA A LISTA DE TODOS OS LINKS PARA OS NERDCASTS
lynx --source http://jovemnerd.com.br/feed/?cat=42 | awk '/link>http\:\/\/jovemnerd\.com\.br\/nerdcast\// {print $1}' | sed -e :a -e 's/<[^>]*>//g' > nerdcast.list;

fi

###################################################
# ATENCAO - CONFIGURACOES DO SISTEMA - ATENCAO
###################################################

# CONFIGURACOES DE FEED
FEED="http://feed.nerdcast.com.br/";

###################################################
# DEFINICAO DE FUNCOES
###################################################

# FUNCAO PARA ATUALIZAR LISTA

update()
{

# BAIXA LISTA TEMPORARIA
lynx --source "$FEED" -connect_timeout=120| awk '/link>http\:\/\/jovemnerd\.com\.br\/nerdcast\// {print $1}' | sed -e :a -e 's/<[^>]*>//g' > /tmp/nerdcast.tmp;

# VERIFICA A DIFERENCAO ENTRE A LISTA LOCAL E A LISTA DO SERVIDOR
LASTNC=$(diff nerdcast.list /tmp/nerdcast.tmp | sed -n '2p' | cut -c 3-)
# VERIFICA SE $LASTNC TEM ALGUM VALOR ATRIBUIDO
if [ ! -z $LASTNC ];

then
COMMENT_ID=$(lynx --source $LASTNC -connect_timeout=120| grep comment_post_ID | awk '{ print $4 }' | cut -b 8-20 | sed 's/[^0-9]//g')
# SINCRONIZA A LISTA LOCAL COM A TEMPORARIA
cat /tmp/nerdcast.tmp > nerdcast.list && echo "Lista atualizada!"

echo $LASTNC;

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
cat nerdcast.list | grep $1
}

###############################
# FUNCAO PARA BAIXAR NERDCAST
###############################

get()
{
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
    jn comment numero_nerdcast nome url email comentario
    Para mais informações:  jn --help"
;;

esac
