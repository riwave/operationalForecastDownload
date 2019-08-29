# operationalForecastDownload
Simple scripts to download operational forecasts
#     Scripts to fetch NOAA forecasts via CURL, using WGRIB2, NCO, and CDO for post-processing.

You can use ssmtp for automatic e-mail messages:


http://andreferraro.wordpress.com/2009/04/30/linux-enviando-email-gmail-bash-linha-de-comando-ssmtp-ubuntu-jaunty-904/


sudo apt-get install ssmtp

abrir (como root) o arquivo /etc/ssmtp/ssmtp.conf apagar tudo e colocar exatamente:

FromLineOverride=NO
Mailhub=smtp.gmail.com:465
UseTLS=YES

agora abrir (como root) o arquivo /etc/ssmtp/revaliases e colocar os e-mails de cada usuário:

root:seu-email@gmail.com:smtp.gmail.com:465
ricardo:seu-email@gmail.com:smtp.gmail.com:465

no diretorio /etc/ssmtp/
chmod +r *

https://myaccount.google.com/lesssecureapps
turn on Less secure app access



Para enviar o e-mail primeiro cria um arquivo texto com a mensagem e detalhes. Por exemplo (email.txt):

To: riwave@gmail.com
Subject: Backup problem

backup error, please check!


em seguida digita o comando abaixo no terminal:

ssmtp email-destino@dominio.com -auseu-email@gmail -apsua-senha < email.txt



A linha acima executa o sSMTP com os parâmetros:

    * email-destino – substitua pelo e-mail do destinatário;
    * -auseue-mail – substitua pelo seu e-mail do Gmail, porém não esqueça de colocar a opção -au antes;
    * -apsua-senha – substitua pela sua senha do Gmail, porém sem esquecer de colocar -ap antes;
    * < emai.txt – encaminha o conteúdo do arquivo email.txt, ou seja, sua mensagem para o programa sSMTP. Observação: Pule uma linha entre o assunto (subject) e a mensagem.



Problemas: Nao aceita senhas com certos caracteres


