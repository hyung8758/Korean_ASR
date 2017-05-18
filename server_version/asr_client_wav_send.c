#include <stdio.h>  
#include <stdlib.h>  
#include <string.h>  
#include <unistd.h>  
#include <arpa/inet.h>  
#include <fcntl.h>  
#include <sys/types.h>  
#include <sys/socket.h>  
    
#define BUFSIZE 128

#define COIN_ADDRESS "106.254.15.66"
    
void error_handling(char *message);  
    
int main(int argc, char **argv)  
{  
  int fd;  
  int sd;  
        
  char buf[BUFSIZE];  
  int len;  
  struct sockaddr_in serv_addr;  

   
  if(argc!=3){  
    printf("Usage : %s <port> <wav file name>\n", argv[0]);  
    exit(1);  
  }  
         

  /* step1. 서버 연결*/
  /* 서버 접속을 위한 소켓 생성 */  
  sd=socket(PF_INET, SOCK_STREAM, 0);     
  if(sd == -1)  
    error_handling("socket() error");  
       
  memset(&serv_addr, 0, sizeof(serv_addr));  
  serv_addr.sin_family=AF_INET;  
  serv_addr.sin_addr.s_addr=inet_addr(COIN_ADDRESS);  
  serv_addr.sin_port=htons(atoi(argv[1]));  
  
  if( connect(sd, (struct sockaddr*)&serv_addr, sizeof(serv_addr))==-1 )  
    error_handling("connect() error!");   

  /* step2. 파일 전송 */
  /* 수신 한 데이터를 저장 할 파일 오픈 */  
  fd = open(argv[2], O_RDONLY );
  if(fd == -1)
    error_handling("File open error");
     
  /* 데이터를 전송 받아서 파일에 저장한다 */  
  while( (len=read(fd, buf, BUFSIZE )) != 0 )  
  {  
    write(sd, buf, len);   
  }  

  /* 데이터 전송후 소켓의 일부(전송영역)를 닫음 */
  if( shutdown(sd, SHUT_WR) == -1 )
    error_handling("shutdown error");
       
  /* /\* 전송해 준것에 대한 감사의 메시지 전달 *\/   */
  /* len = read(sd, cbuf, BUFSIZE); */
  /* write(1, cbuf, len); */


  /* step4. ASR 결과 수신 */
  while((len=read(sd,buf,BUFSIZE))!=0)
  {
    write(1,buf,len);
  }

  close(fd);  
  close(sd);  
  return 0;  
}  
   
void error_handling(char *message)  
{  
  fputs(message, stderr);  
  fputc('\n', stderr);  
  exit(1);  
}
