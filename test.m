function [] = test(filename,ref,showFigure)

if(~exist('showFigure'))
    showFigure=true;
end

cameraFactor=0.41;
img=imread(filename);
ref=imresize(ref,[747,1385]);
img=imresize(img,[747,1385]);
original=img;

ref=rgb2hsv(ref);
img=rgb2hsv(img);
ref=ref(:,:,1);
img=img(:,:,1);

diff=abs(ref-img);
%Filtruje z szumu
diff=imgaussfilt(diff,5);
%Progowanie
diff=im2bw(diff,0.25);

se = strel('sphere',5);
diff = imerode(diff,se);
se = strel('sphere',5);
diff = imdilate(diff,se);

%Obszar zainteresowania
%Roi A=(39,167),B=(438,402)
roiA=[282,101];
roiB=[513,794];
roi=zeros(size(diff));
roi(roiA(1):roiB(1)-1,roiA(2):roiB(2)-1)=ones(roiB(1)-roiA(1),roiB(2)-roiA(2));
diff=diff.*roi;

if(showFigure)
    diff3(:,:,1)=diff;
    diff3(:,:,2)=diff;
    diff3(:,:,3)=diff;
    imshow(uint8(diff3).*original)
    hold on
end

%Tu wyszukuje kształty
[B,L] = bwboundaries(diff, 'noholes');
STATS = regionprops(L, 'all');

%Jeśli jest więcej obiektów niż jeden
if(length(STATS)>1)
    disp(sprintf('%s - rolka rozwinięta',filename));
    return
end

%Licze prostokąt opisujący rolkę
BOX=[min(STATS(1).PixelList(:,1)),min(STATS(1).PixelList(:,2)),...
    max(STATS(1).PixelList(:,1)),max(STATS(1).PixelList(:,2))];
%Liczę wysokość, szerokość prostokąta
W=BOX(3)-BOX(1);
H=BOX(4)-BOX(2);

%Liczę punkty kontrolne
%   __P1_______________P3__
%  |                       |
% P5                       P6
%  |__P2_______________P4__|
%
%P1,P2
Ind=find(STATS(1).PixelList(:,1) ==  uint16(BOX(1)+0.1*W));
testPoint(:,1)=[uint16(BOX(1)+0.1*W),min(STATS(1).PixelList(Ind,2))];
testPoint(:,2)=[uint16(BOX(1)+0.1*W),max(STATS(1).PixelList(Ind,2))];
%P3,P4
Ind=find(STATS(1).PixelList(:,1) ==  uint16(BOX(3)-0.1*W));
testPoint(:,3)=[uint16(BOX(3)-0.1*W),min(STATS(1).PixelList(Ind,2))];
testPoint(:,4)=[uint16(BOX(3)-0.1*W),max(STATS(1).PixelList(Ind,2))];
%P5
Ind=find(STATS(1).PixelList(:,2) ==  ...
    uint16((testPoint(2,2)+testPoint(2,1))/2));
testPoint(:,5)=[min(STATS(1).PixelList(Ind,1)),...
    uint16((testPoint(2,2)+testPoint(2,1))/2)];
%P6
Ind=find(STATS(1).PixelList(:,2) ==  ...
    uint16((testPoint(2,4)+testPoint(2,3))/2));
testPoint(:,6)=[max(STATS(1).PixelList(Ind,1)),...
    uint16((testPoint(2,4)+testPoint(2,3))/2)];

%Liczę długości
%len1=P2-P1
%len2=P4-P3
%len3=P6-P5

len1=(testPoint(2,2)-testPoint(2,1))*cameraFactor;
len2=(testPoint(2,4)-testPoint(2,3))*cameraFactor;
len3=(testPoint(1,6)-testPoint(1,5))*cameraFactor;

%Rysuje punkty kontrolne
if(showFigure)
    for i=1:6
        plot(testPoint(1,i),testPoint(2,i),'+')
    end
end

if(abs(len1-len2)>0.1*(len1+len2)/2)
    disp(sprintf('%s - stożkowatość',filename))
    return
end

if(abs(len1-50)>5 | abs(len2-50)>5 | abs(len3-255)>5)
    disp(sprintf('%s - rolka za długa/gruba',filename));
    return
end
disp(sprintf('%s - rolka poprawna',filename));
end