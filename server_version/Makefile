all : ASR_client_sox ASR_client_wav LM_client ASR_client_sox_16khz

ASR_client_sox :
	gcc -W -Wall -o ASR_client_sox asr_client_sox_record.c
ASR_client_wav :
	gcc -W -Wall -o ASR_client_wav asr_client_wav_send.c
LM_client :
	gcc -W -Wall -o LM_client buildLM_client.c
ASR_client_sox_16khz :
	gcc -W -Wall -o ASR_client_sox_16khz asr_client_sox_record_16khz.c

clean :
	rm -f ASR_client_sox
	rm -f ASR_client_wav
	rm -f LM_client
	rm -f ASR_client_sox_16khz
