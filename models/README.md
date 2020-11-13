# diy usage
- Hyungwon Yang
- 11.12.2020

### Instruction.
1. If you have your own corpus and want to train an ASR model with it, please use kaldi_tutorial script in my github.
2. Once you trained your model, locate necessary files to the diy folder.
3. You must include following files based on your trained model type and write the model type in the run_asr.sh(find $model_type variable) script.
   - mono: HCLG.fst, final.mdl, words.txt
   - tri1: HCLG.fst, final.mdl, words.txt
   - tri2: HCLG.fst, final.mdl, words.txt, final.mat
   - tri3: HCLG.fst, final.mdl, words.txt, final.mat, final.alimdl, phones/
   - dnn : HCLG.fst, final.mdl, words.txt, final.mat
