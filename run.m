%To uruchamiać
ref=imread('ref1.jpg');
files=dir('photos');
files=files(~ismember({files.name},{'.','..'}));

for i=1:length(files)
    filename=strcat('photos/',files(i).name);
    test(filename,ref,false);
end