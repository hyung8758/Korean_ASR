# -*- coding: utf-8 -*-
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com
"""
This script generates FA requisite files from sound wav and text file.

2 input arguments: sound wav and text file.

"""

import sys
import os
import re
import wave

# Arguments check.
if len(sys.argv) != 3:
    print(len(sys.argv))
    raise ValueError('The number of input arguments is wrong.')

# sound and text directory
data_dir = sys.argv[1]
save_dir = sys.argv[2]

if not os.path.exists(save_dir):
    os.makedirs(save_dir)

# Separate data.
whole_list = os.listdir(data_dir)
sound_list=[]
for one in whole_list:
    if re.findall('wav',one) != []:
        sound_list.append(one)

# Sorting the list.
sound_list.sort()

'''
### text

Generate text

text_cont=[]
for rd in text_list:
    with open('/'.join([data_dir,rd]),'r') as txt:
        text_cont.append(txt.read())

with open('/'.join([save_dir,'text']),'w') as text:
    for turn in range(len(sound_list)):
        tmp_sound = re.sub('.wav','',sound_list[turn])
        text.write(tmp_sound + ' ' + text_cont[turn] + '\n')

### textraw

Generate textraw

text_cont=[]
for rd in text_list:
    with open ('/'.join([data_dir,rd]),'r') as txt:
        text_cont.append(txt.read())

with open('/'.join([save_dir,'textraw']),'w') as text:
    for turn in text_cont:
        text.write(turn + '\n')

## segments

Generate segments

print("In this script, segments assumes each file contains one utterance.")
with open('/'.join([save_dir,'segments']),'w') as seg:
    for sd in sound_list:
        sig = wave.open('/'.join([data_dir, sd]), 'rb')
        sig_dur = sig.getnframes() / sig.getframerate()
        dur = "{0:.2f}".format(sig_dur)
        if float(dur) > sig_dur:
            tmp_dur = float(dur)
            tmp_dur -= 0.001
            dur = str(tmp_dur)
        nowav=re.sub('.wav','',sd)
        seg.write(nowav + ' ' + nowav + ' ' + '0' + ' ' + dur + '\n')
'''

# wav.scp
'''
Generate wav.scp
'''
with open ('/'.join([save_dir,'wav.scp']),'w') as scp:
    for win in range(len(sound_list)):
        nowav = re.sub('.wav', '', sound_list[win])
        scp.write(nowav + ' ' + '/'.join([data_dir,sound_list[win]]) + '\n')

# utt2spk
'''
Generate utt2spk
'''
with open ('/'.join([save_dir,'utt2spk']),'w') as u2s:
    dir_name = data_dir.split('/')[-1]
    if dir_name == '':
        print("WARNING: Please remove '/' at the end of the data directory path next time.")
        dir_name =data_dir.split('/')[-2]
    for uin in range(len(sound_list)):
        utwav = re.sub('.wav', '', sound_list[uin])
        u2s.write(utwav + ' ' + dir_name + '\n')

print("All prerequisite data files are successfully generated.")
