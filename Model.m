%dependent files: Library/FileTime_29Jun2011/GetFileTime.m

classdef Model < handle
    %points 3xN
    properties
        ply_filename = '';
        node_xyz = [];
        triangle_node;
        node_rgb;
        normal = [];
    end
    
    methods
        %% read a model, output 3D points
        function self = readModel(self)
            addpath('E:/matlabCode/Library/FileTime_29Jun2011');
            Path = self.ply_filename;
            cachepath = [self.ply_filename, '.cache'];
            if (exist(cachepath))
                timeOrigin = GetFileTime(self.ply_filename, 'Local', 'Write');
                timeCache = GetFileTime(cachepath, 'Local', 'Write');
                flag = 1;
                for i = 1:6
                    if timeOrigin(i) ~= timeCache(i)
                        if timeOrigin(i) > timeCache(i)
                            flag = 0;
                        end
                        break;
                    end
                end
                
                if (flag)          
                    S = load(cachepath, '-mat');
                    self.node_xyz = S.self.node_xyz;
                    self.triangle_node = S.self.triangle_node;
                    self.node_rgb = S.self.node_rgb;
                    self.normal = S.self.normal;
                    fprintf('[read model] loaded cached model %s successfully\n', self.ply_filename);
                    return;
                else
                    delete(cachepath);
                    self.node_xyz = [];
                    self.triangle_node = [];
                    self.node_rgb = [];
                end
            end
            
            %
            %  Open the input file in "read text" mode.
            %
            [ fid, Msg ] = fopen ( self.ply_filename, 'rt' );
            
            if ( fid == -1 )
                error ( Msg );
            end
            
            Buf = fscanf ( fid, '%s', 1 );
            
            if ( ~strcmp ( Buf, 'ply' ) )
                fclose ( fid );
                error('Not a PLY file.');
            end
            %
            %  Read the header.
            %
            Position = ftell(fid);
            Format = '';
            NumComments = 0;
            Comments = {};
            NumElements = 0;
            NumProperties = 0;
            Elements = [];
            ElementCount = [];
            PropertyTypes = [];
            ElementNames = {};  % list of element names in the order they are stored in the file
            PropertyNames = [];  % structure of lists of property names
            
            while ( 1 )
                %
                %  Read a line from the file.
                %
                Buf = fgetl ( fid );
                BufRem = Buf;
                Token = {};
                Count = 0;
                %
                %  Split the line into tokens.
                %
                while ( ~isempty(BufRem) )
                    
                    [ tmp, BufRem ] = strtok(BufRem);
                    %
                    %  Count the tokens.
                    %
                    if ( ~isempty ( tmp ) )
                        Count = Count + 1;
                        Token{Count} = tmp;
                    end
                    
                end
                %
                %  Parse the line.
                %
                if ( Count )
                    
                    switch lower ( Token{1} )
                        %
                        %  Read the data format.
                        %
                        case 'format'
                            
                            if ( 2 <= Count )
                                
                                Format = lower ( Token{2} );
                                
                                if ( Count == 3 & ~strcmp ( Token{3}, '1.0' ) )
                                    fclose ( fid );
                                    error('Only PLY format version 1.0 supported.');
                                end
                            end
                            %
                            %  Read a comment.
                            %
                        case 'comment'
                            
                            NumComments = NumComments + 1;
                            Comments{NumComments} = '';
                            for i = 2 : Count
                                Comments{NumComments} = [Comments{NumComments},Token{i},' '];
                            end
                            %
                            %  Read an element name.
                            %
                        case 'element'
                            
                            if ( 3 <= Count )
                                
                                if ( isfield(Elements,Token{2}) )
                                    fclose ( fid );
                                    error(['Duplicate element name, ''',Token{2},'''.']);
                                end
                                
                                NumElements = NumElements + 1;
                                NumProperties = 0;
                                Elements = setfield(Elements,Token{2},[]);
                                PropertyTypes = setfield(PropertyTypes,Token{2},[]);
                                ElementNames{NumElements} = Token{2};
                                PropertyNames = setfield(PropertyNames,Token{2},{});
                                CurElement = Token{2};
                                ElementCount(NumElements) = str2double(Token{3});
                                
                                if ( isnan(ElementCount(NumElements)) )
                                    fclose ( fid );
                                    error(['Bad element definition: ',Buf]);
                                end
                                
                            else
                                
                                error(['Bad element definition: ',Buf]);
                                
                            end
                            %
                            %  Read an element property.
                            %
                        case 'property'
                            
                            if ( ~isempty(CurElement) & Count >= 3 )
                                
                                NumProperties = NumProperties + 1;
                                eval(['tmp=isfield(Elements.',CurElement,',Token{Count});'],...
                                    'fclose(fid);error([''Error reading property: '',Buf])');
                                
                                if ( tmp )
                                    error(['Duplicate property name, ''',CurElement,'.',Token{2},'''.']);
                                end
                                %
                                %  Add property subfield to Elements.
                                %
                                eval(['Elements.',CurElement,'.',Token{Count},'=[];'], ...
                                    'fclose(fid);error([''Error reading property: '',Buf])');
                                %
                                %  Add property subfield to PropertyTypes and save type.
                                %
                                eval(['PropertyTypes.',CurElement,'.',Token{Count},'={Token{2:Count-1}};'], ...
                                    'fclose(fid);error([''Error reading property: '',Buf])');
                                %
                                %  Record property name order.
                                %
                                eval(['PropertyNames.',CurElement,'{NumProperties}=Token{Count};'], ...
                                    'fclose(fid);error([''Error reading property: '',Buf])');
                                
                            else
                                
                                fclose ( fid );
                                
                                if ( isempty(CurElement) )
                                    error(['Property definition without element definition: ',Buf]);
                                else
                                    error(['Bad property definition: ',Buf]);
                                end
                                
                            end
                            %
                            %  End of header.
                            %
                        case 'end_header'
                            break;
                            
                    end
                end
            end
            %
            %  Set reading for specified data format.
            %
            if ( isempty ( Format ) )
                warning('Data format unspecified, assuming ASCII.');
                Format = 'ascii';
            end
            
            switch Format
                
                case 'ascii'
                    Format = 0;
                case 'binary_little_endian'
                    Format = 1;
                case 'binary_big_endian'
                    Format = 2;
                otherwise
                    fclose ( fid );
                    error(['Data format ''',Format,''' not supported.']);
                    
            end
            %
            %  Read the rest of the file as ASCII data...
            %
            if ( ~Format )
                Buf = fscanf ( fid, '%f' );
                BufOff = 1;
            else
                %
                %  ...or, close the file, and reopen in "read binary" mode.
                %
                fclose ( fid );
                %
                %  Reopen the binary file as LITTLE_ENDIAN or BIG_ENDIAN.
                %
                if ( Format == 1 )
                    fid = fopen ( Path, 'r', 'ieee-le.l64' );
                else
                    fid = fopen ( Path, 'r', 'ieee-be.l64' );
                end
                %
                %  Find the end of the header again.
                %  Using ftell on the old handle doesn't give the correct position.
                %
                BufSize = 8192;
                Buf = [ blanks(10), char(fread(fid,BufSize,'uchar')') ];
                i = [];
                tmp = -11;
                
                while ( isempty(i) )
                    %
                    %  Look for end_header + CR/LF
                    %
                    i = findstr(Buf,['end_header',13,10]);
                    %
                    %  Look for end_header + LF
                    %
                    i = [i,findstr(Buf,['end_header',10])];
                    
                    if ( isempty(i) )
                        tmp = tmp + BufSize;
                        Buf = [Buf(BufSize+1:BufSize+10),char(fread(fid,BufSize,'uchar')')];
                    end
                    
                end
                %
                %  Seek to just after the line feed
                %
                fseek ( fid, i + tmp + 11 + (Buf(i + 10) == 13), -1 );
                
            end
            %
            %  Read element data.
            %
            %  PLY and MATLAB data types (for fread)
            %
            PlyTypeNames = {'char','uchar','short','ushort','int','uint','float','double', ...
                'char8','uchar8','short16','ushort16','int32','uint32','float32','double64'};
            
            MatlabTypeNames = {'schar','uchar','int16','uint16','int32','uint32','single','double'};
            
            SizeOf = [1,1,2,2,4,4,4,8];
            
            for i = 1 : NumElements
                %
                %  get current element property information
                %
                eval(['CurPropertyNames=PropertyNames.',ElementNames{i},';']);
                eval(['CurPropertyTypes=PropertyTypes.',ElementNames{i},';']);
                NumProperties = size(CurPropertyNames,2);
                %
                %  Read ASCII data.
                %
                if ( ~Format )
                    
                    for j = 1 : NumProperties
                        
                        Token = getfield(CurPropertyTypes,CurPropertyNames{j});
                        
                        if ( strcmpi(Token{1},'list') )
                            Type(j) = 1;
                        else
                            Type(j) = 0;
                        end
                        
                    end
                    %
                    %  Parse the buffer.
                    %
                    if ( ~any(Type) )
                        %
                        %  No list types
                        %
                        Data = reshape ( ...
                            Buf(BufOff:BufOff+ElementCount(i)*NumProperties-1), ...
                            NumProperties, ElementCount(i) )';
                        
                        BufOff = BufOff + ElementCount(i) * NumProperties;
                        
                    else
                        
                        ListData = cell(NumProperties,1);
                        
                        for k = 1 : NumProperties
                            ListData{k} = cell(ElementCount(i),1);
                        end
                        %
                        %  list type
                        %
                        for j = 1 : ElementCount(i)
                            for k = 1 : NumProperties
                                
                                if ( ~Type(k) )
                                    Data(j,k) = Buf(BufOff);
                                    BufOff = BufOff + 1;
                                else
                                    tmp = Buf(BufOff);
                                    ListData{k}{j} = Buf(BufOff+(1:tmp))';
                                    BufOff = BufOff + tmp + 1;
                                end
                                
                            end
                        end
                        
                    end
                    %
                    %  Read binary data.
                    %
                else
                    %
                    %  Translate PLY data type names to MATLAB data type names
                    %
                    ListFlag = 0;
                    SameFlag = 1;
                    
                    for j = 1 : NumProperties
                        
                        Token = getfield(CurPropertyTypes,CurPropertyNames{j});
                        %
                        %  Non-list type.
                        %
                        if ( ~strcmp(Token{1},'list' ) )
                            
                            tmp = rem(strmatch(Token{1},PlyTypeNames,'exact')-1,8)+1;
                            
                            if ( ~isempty(tmp) )
                                
                                TypeSize(j) = SizeOf(tmp);
                                Type{j} = MatlabTypeNames{tmp};
                                TypeSize2(j) = 0;
                                Type2{j} = '';
                                
                                SameFlag = SameFlag & strcmp(Type{1},Type{j});
                                
                            else
                                
                                fclose(fid);
                                error(['Unknown property data type, ''',Token{1},''', in ', ...
                                    ElementNames{i},'.',CurPropertyNames{j},'.']);
                                
                            end
                            %
                            %  List type.
                            %
                        else
                            
                            if ( length(Token) == 3 )
                                
                                ListFlag = 1;
                                SameFlag = 0;
                                tmp = rem(strmatch(Token{2},PlyTypeNames,'exact')-1,8)+1;
                                tmp2 = rem(strmatch(Token{3},PlyTypeNames,'exact')-1,8)+1;
                                
                                if ( ~isempty(tmp) & ~isempty(tmp2) )
                                    TypeSize(j) = SizeOf(tmp);
                                    Type{j} = MatlabTypeNames{tmp};
                                    TypeSize2(j) = SizeOf(tmp2);
                                    Type2{j} = MatlabTypeNames{tmp2};
                                else
                                    fclose(fid);
                                    error(['Unknown property data type, ''list ',Token{2},' ',Token{3},''', in ', ...
                                        ElementNames{i},'.',CurPropertyNames{j},'.']);
                                end
                                
                            else
                                
                                fclose(fid);
                                error(['Invalid list syntax in ',ElementNames{i},'.',CurPropertyNames{j},'.']);
                                
                            end
                            
                        end
                        
                    end
                    %
                    %  Read the file.
                    %
                    if ( ~ListFlag )
                        %
                        %  No list types, all the same type (fast)
                        %
                        if ( SameFlag )
                            
                            Data = fread(fid,[NumProperties,ElementCount(i)],Type{1})';
                            %
                            %  No list types, mixed type.
                            %
                        else
                            
                            Data = zeros(ElementCount(i),NumProperties);
                            
                            for j = 1 : ElementCount(i)
                                for k = 1 : NumProperties
                                    Data(j,k) = fread(fid,1,Type{k});
                                end
                            end
                            
                        end
                        
                    else
                        
                        ListData = cell(NumProperties,1);
                        
                        for k = 1 : NumProperties
                            ListData{k} = cell(ElementCount(i),1);
                        end
                        
                        if ( NumProperties == 1 )
                            
                            BufSize = 512;
                            SkipNum = 4;
                            j = 0;
                            %
                            %  List type, one property (fast if lists are usually the same length)
                            %
                            while ( j < ElementCount(i) )
                                
                                BufSize = min(ElementCount(i)-j,BufSize);
                                Position = ftell(fid);
                                %
                                %  Read in BufSize count values, assuming all counts = SkipNum
                                %
                                [Buf,BufSize] = fread(fid,BufSize,Type{1},SkipNum*TypeSize2(1));
                                %
                                %  Find first count that is not SkipNum
                                %
                                Miss = find(Buf ~= SkipNum);
                                %
                                %  Seek back to after first count
                                %
                                fseek(fid,Position + TypeSize(1),-1);
                                
                                if ( isempty(Miss) )
                                    %
                                    %  All counts are SkipNum.
                                    %
                                    Buf = fread(fid,[SkipNum,BufSize],[int2str(SkipNum),'*',Type2{1}],TypeSize(1))';
                                    %
                                    %  Undo the last skip.
                                    %
                                    fseek(fid,-TypeSize(1),0);
                                    
                                    for k = 1:BufSize
                                        ListData{1}{j+k} = Buf(k,:);
                                    end
                                    
                                    j = j + BufSize;
                                    BufSize = floor ( 1.5 * BufSize );
                                    
                                else
                                    %
                                    %  Some counts are SkipNum.
                                    %
                                    if ( 1 < Miss(1) )
                                        
                                        Buf2 = fread ( fid, [SkipNum,Miss(1)-1],[int2str(SkipNum),'*',Type2{1}],TypeSize(1))';
                                        
                                        for k = 1:Miss(1)-1
                                            ListData{1}{j+k} = Buf2(k,:);
                                        end
                                        
                                        j = j + k;
                                        
                                    end
                                    %
                                    %  Read in the list with the missed count.
                                    %
                                    SkipNum = Buf(Miss(1));
                                    j = j + 1;
                                    ListData{1}{j} = fread ( fid, [1,SkipNum],Type2{1} );
                                    BufSize = ceil ( 0.6 * BufSize );
                                    
                                end
                            end
                            
                        else
                            %
                            %  List type(s), multiple properties (slow)
                            %
                            Data = zeros(ElementCount(i),NumProperties);
                            
                            for j = 1 : ElementCount(i)
                                for k = 1 : NumProperties
                                    
                                    if ( isempty(Type2{k}) )
                                        Data(j,k) = fread(fid,1,Type{k});
                                    else
                                        tmp = fread(fid,1,Type{k});
                                        ListData{k}{j} = fread(fid,[1,tmp],Type2{k});
                                    end
                                    
                                end
                            end
                        end
                    end
                end
                %
                %  Put data into Elements structure
                %
                for k = 1 : NumProperties
                    
                    if ( ( ~Format & ~Type(k) ) | (Format & isempty(Type2{k})) )
                        eval(['Elements.',ElementNames{i},'.',CurPropertyNames{k},'=Data(:,k);']);
                    else
                        eval(['Elements.',ElementNames{i},'.',CurPropertyNames{k},'=ListData{k};']);
                    end
                    
                end
                
            end
            
            clear Data
            clear ListData;
            
            fclose ( fid );
            %
            %  Output the data as a triangular mesh pair.
            %
            %  Find vertex element field.
            %
            Name = {'vertex','Vertex','point','Point','pts','Pts'};
            Names = [];
            
            for i = 1 : length(Name)
                
                if ( any ( strcmp ( ElementNames, Name{i} ) ) )
                    Names = getfield(PropertyNames,Name{i});
                    Name = Name{i};
                    break;
                end
                
            end
            
            if ( any(strcmp(Names,'x')) & any(strcmp(Names,'y')) & any(strcmp(Names,'z')) )
                eval(['self.node_xyz=[Elements.',Name,'.x,Elements.',Name,'.y,Elements.',Name,'.z];']);
            else
                self.node_xyz = zeros(1,3);
            end
            self.node_xyz = self.node_xyz';
            
            if (any(strcmp(Names, 'red')) & any(strcmp(Names, 'green')) & any(strcmp(Names, 'blue')) )
                eval(['self.node_rgb = [Elements.', Name, '.red, Elements.', Name, '.green, Elements.', Name, '.blue];']);
            elseif (any(strcmp(Names, 'diffuse_red')) & any(strcmp(Names, 'diffuse_green')) & any(strcmp(Names, 'diffuse_blue')) )
                eval(['self.node_rgb = [Elements.', Name, '.diffuse_red, Elements.', Name, '.diffuse_green, Elements.', Name, '.diffuse_blue];']);
            else
                self.node_rgb = zeros(1, 3);
            end
            self.node_rgb = self.node_rgb';
         
            % normal
            if (any(strcmp(Names, 'nx')) & any(strcmp(Names, 'ny')) & any(strcmp(Names, 'nz')) )
                eval(['self.normal = [Elements.', Name, '.nx, Elements.', Name, '.ny, Elements.', Name, '.nz];']);
            end
            self.normal = self.normal';
            
            % Find face element field
            self.triangle_node = [];
            
            Name = {'face','Face','poly','Poly','tri','Tri'};
            Names = [];
            
            for i = 1 : length(Name)
                if ( any(strcmp(ElementNames,Name{i})) )
                    Names = getfield(PropertyNames,Name{i});
                    Name = Name{i};
                    break;
                end
            end
            
            if ( ~isempty(Names) )
                % find vertex indices property subfield
                PropertyName = {'vertex_indices','vertex_indexes','vertex_index','indices','indexes'};
                
                for i = 1 : length(PropertyName)
                    if ( any(strcmp(Names,PropertyName{i})) )
                        PropertyName = PropertyName{i};
                        break;
                    end
                end
                %
                %  Convert face index list to triangular connectivity.
                %
                if ( ~iscell(PropertyName) )
                    
                    eval(['FaceIndices=Elements.',Name,'.',PropertyName,';']);
                    N = length(FaceIndices);
                    self.triangle_node = zeros(3,N*2);
                    Extra = 0;
                    
                    for k = 1 : N
                        
                        self.triangle_node(1:3,k) = FaceIndices{k}(1:3)';
                        
                        for j = 4 : length(FaceIndices{k})
                            Extra = Extra + 1;
                            self.triangle_node(1,N + Extra) = FaceIndices{k}(1);
                            self.triangle_node(2,N + Extra) = FaceIndices{k}(j-1);
                            self.triangle_node(3,N + Extra) = FaceIndices{k}(j);
                        end
                        
                    end
                    %
                    %  Add 1 to each vertex value; PLY vertices are zero based.
                    %
                    self.triangle_node = self.triangle_node(:,1:N+Extra) + 1;
                    
                end
            end
            
            save(cachepath, 'self', '-mat');
            
            return
        end
        %% add bottom points
        function addBottom(self)
            maxny = max(self.node_xyz(2, :));
            node = [self.node_xyz(1, :); zeros(1, size(self.node_xyz, 2)) + maxny; self.node_xyz(3, :)];
            self.node_xyz = [node, self.node_xyz];
            self.node_rgb = [repmat([150, 100, 100]', 1, size(self.node_rgb, 2)), self.node_rgb];
            self.normal = [repmat([0,1,0]', 1, size(self.normal, 2)), self.normal];
        end
        %% show 3D model
        function show(self)
            if (size(self.triangle_node, 1) ~= 0 && size(self.triangle_node, 2) ~= 0)
                trisurf ( self.triangle_node', self.node_xyz(1,:), self.node_xyz(2,:), self.node_xyz(3,:) );
            else  
                scatter3 (self.node_xyz(1,:), self.node_xyz(2,:), self.node_xyz(3,:), '.', 'cdata', self.node_rgb'./255.0);
            end
            axis equal;
            xlabel ( '<--- X --->' );
            ylabel ( '<--- Y --->' );
            zlabel ( '<--- Z --->' );
            title ( self.ply_filename );
        end
        %% set ply filename
        function self = Model(filename)
            self.ply_filename = filename;
        end
        %% the relationship of points and edges
        function edges = tree(self)
            len = size(self.triangle_node, 2);
            edges = cell(size(self.node_xyz, 2), 1);
            for i = 1:len
                for j = 1:3
                    idx = self.triangle_node(j, i);
                    edges{idx} = [edges{idx}, self.triangle_node(mod(j, 3) + 1, i), self.triangle_node(mod(j+1, 3) + 1, i)];
                end
            end
            for i = 1:size(self.node_xyz, 2)
                edges{i} = unique(edges{i});
                
                neighbors = self.node_xyz(:, edges{i});
                dif = neighbors - repmat(self.node_xyz(:, i), 1, length(edges{i}));
                
                %left right up down
                tmpdif = dif;
                tmpdif(2, dif(1, :) >= 0) = nan;
                [~, idxLeft] = min(abs(tmpdif(2, :) ) );
                tmpdif = dif;
                tmpdif(2, dif(1, :) <= 0) = nan;
                [~, idxRight] = min(abs(tmpdif(2, :)) );
                tmpdif = dif;
                tmpdif(1, dif(2, :) <= 0) = nan;
                [~, idxUp] = min(abs(tmpdif(1, :)) );
                tmpdif = dif;
                tmpdif(1, dif(2, :) >= 0) = nan;
                [~, idxDown] = min(abs(tmpdif(1, :) ) );
                
                edges{i} = edges{i}([idxLeft, idxRight, idxUp, idxDown]);
            end
        end
        %% read camera params
        function [K, R, t, sfmIndex] = readPose(poseDir)
            intrincfile = [poseDir '/cameras_v2.txt'];
            fid = fopen(intrincfile);
            while 1
                buf = fgetl(fid);
                if (length(buf) <= 0 )
                    continue;
                end
                if (strcmp(buf(1), '#') ~= 1)
                    break;
                end
            end
            filenum = sscanf(buf, '%d');
            
            P = zeros(3, 4, filenum);
            R = zeros(3, 3, filenum);
            t = zeros(3, 1, filenum);
            K = ones(3, 3, filenum);
            
            sfmIndex = zeros(filenum, 1);
            for i = 1:filenum
                buf = fscanf(fid, '%s', 2);
                str = strsplit(buf, '\');
                str = str{length(str)};
                orgIndex = sscanf(str, '%d.jpg');
                sfmIndex(i) = orgIndex;
                buf = fscanf(fid, '%f', 3);
                K(:, :, i) = [buf(1), 0, buf(2); 0, buf(1), buf(3); 0, 0, 1];
                buf = fscanf(fid, '%f', 26);
            end
            
            fclose(fid);
            
            posefiles = dir([poseDir '/txt/*.txt']);
            %filenum = length(posefiles);
            
            if (filenum ~= length(posefiles))
                fprintf('Error: num of pose files not equal to filenum value');
            end
            
            for i = 1:filenum
                posefile = [poseDir '/txt/' posefiles(i).name];
                fid = fopen(posefile, 'rt');
                buf = fscanf ( fid, '%s', 1 );
                buf = fscanf(fid, '%f');
                fclose(fid);
                
                P(:, :, i) = reshape(buf, 4, 3)';
                RT = inv(K(:, :, i))*P(:, :, i);
                R(:, :, i) = RT(1:3, 1:3);
                t(:,:,i) = RT(1:3, 4);
                
            end
        end
        %% show axis changes
        function draw(R, t)
            axis = [0, 0, 0; 0.01, 0, 0; 0, 0.01, 0; 0, 0, 0.01];
            %    drawsingle(axis, 0);
            xlabel('x-->');
            ylabel('y-->');
            zlabel('z-->');
            for i = 1:size(R, 3)
                naxis = (axis - [t(:, :, i)';t(:, :, i)';t(:, :, i)';t(:, :, i)'])*R(:, :, i);
                drawsingle(naxis, i);
            end
        end
        
        function drawsingle(axis, no)
            hold on;
            line([axis(1, 1), axis(2, 1)], [axis(1, 2), axis(2, 2)],[axis(1, 3), axis(2, 3)], 'Color', 'r');
            view(3);
            line([axis(1, 1), axis(3, 1)], [axis(1, 2), axis(3, 2)],[axis(1, 3), axis(3, 3)], 'Color', 'g');
            line([axis(1, 1), axis(4, 1)], [axis(1, 2), axis(4, 2)],[axis(1, 3), axis(4, 3)], 'Color', 'b');
            
            text(axis(1, 1), axis(1, 2), axis(1, 3), num2str(no));
        end
        %% show projection contours
        function showProjection(self)
            [K, R, t, sfmIndex] = self.readPose(poseDir);
            grid on;
            draw(R, t);
            %save('sfmRt', 'R', 't');
            self.readModel();
            
            DrawScene = 0;
            if DrawScene
                self.show();
            end
            DrawContour = 1;
            if DrawContour
                row = 1080;
                col = 1920;
                level = 1;
                
                for framenum = 1:size(R, 3)
                    node_xy = K(:,:,framenum)*[R(:,:,framenum), t(:,:,framenum)]* [node_xyz; ones(1, size(node_xyz, 2))];
                    node_xy(1, :) = node_xy(1, :) ./ node_xy(3, :);
                    node_xy(2, :) = node_xy(2, :) ./ node_xy(3, :);
                    if 0
                        subplot(121);
                        scatter(node_xy(1, :), -node_xy(2, :), '.', 'cdata', node_rgb'./255);
                        subplot(122);
                        scatter(floor(node_xy(1, :)), floor(node_xy(2, :)), '*', 'cdata', node_rgb'./255 );
                    end
                    saveContour = 1;
                    if saveContour
                        img = zeros(row, col, level);
                        index = ( floor(node_xy(2, :))  > 0 );
                        
                        for i = 1:size(index, 2)
                            if (index(i) > 0)
                                if (floor(node_xy(2, i)) <= 0 || floor(node_xy(1, i)) <= 0)
                                    continue;
                                end
                                %img( floor(node_xy(2, i)), floor(node_xy(1, i)), :) = node_rgb(:,i)'./255;
                                img(floor(node_xy(2, i)), floor(node_xy(1, i))) = 255;
                            end
                        end
                        
                        se = strel('disk', 20);
                        img = imdilate(img, se);
                        %figure, imshow(img);
                        
                        savefile = [savepath num2str(sfmIndex(framenum), '%08d.jpg')];
                        imwrite(img, savefile);
                    end
                end 
            end                
        end
        
        %% 
        function writePly(self, output_filename)
            %normals = points2normals(self.node_xyz);
            
            fin = fopen(output_filename, 'wt');
            
            if size(self.normal, 1) ~= 0
            fprintf(fin, ['ply \n format ascii 1.0 \n element face 0 \n property list uchar int vertex_indices \n element vertex ' ...
        int2str(size(self.node_xyz, 2)) ...
        '\n property float x \n property float y \n property float z \n property float nx \n property float ny \n property float nz \n end_header\n']);
            for i = 1:size(self.node_xyz, 2)
                fprintf(fin, '%f %f %f %f %f %f\n', self.node_xyz(1, i), self.node_xyz(2, i), self.node_xyz(3, i), self.normal(1, i), self.normal(2, i), self.normal(3, i));
            end
            
            elseif size(self.node_rgb, 1) < 2     
                fprintf(fin, ['ply \n format ascii 1.0 \n element face 0 \n property list uchar int vertex_indices \n element vertex ' ...
        int2str(size(self.node_xyz, 2)) ...
        '\n property float x \n property float y \n property float z \n property uchar diffuse_red \n property uchar diffuse_green \n property uchar diffuse_blue \n end_header\n']);
                for i = 1:size(self.node_xyz, 2)
                    fprintf(fin, '%f %f %f %d %d %d\n', self.node_xyz(1, i), self.node_xyz(2, i), self.node_xyz(3, i), self.node_rgb(1,i), self.node_rgb(2,i), self.node_rgb(3,i));
                end
                
                else 
                    fprintf(fin, ['ply \n format ascii 1.0 \n element face 0 \n property list uchar int vertex_indices \n element vertex ' ...
        int2str(size(self.node_xyz, 2)) ...
        '\n property float x \n property float y \n property float z \n end_header\n']);
                for i = 1:size(self.node_xyz, 2)
                    fprintf(fin, '%f %f %f\n', self.node_xyz(1, i), self.node_xyz(2, i), self.node_xyz(3, i));
                end
            end
  
            fclose(fin);
        end
        %%
        function writexyz(self, xyz_filename)
            fin = fopen(xyz_filename, 'wt');
            for i = 1:size(self.node_xyz, 2)
                fprintf(fin, '%f %f %f\n',  self.node_xyz(1, i), self.node_xyz(2, i), self.node_xyz(3, i));
            end
            fclose(fin);
        end
        %% get neighbor
        function value = getZneighbor(z, idx, dx, dy, edges)
            while(dx > 0)
                idx = edges{idx}(2);
                dx = dx - 1;
            end
            while(dy > 0)
                idx = edges{idx}(3);
                dy = dy - 1;
            end
            while(dx < 0)
                idx = edges{idx}(1);
                dx = dx + 1;
            end
            while(dy < 0)
                idx = edges{idx}(4);
                dy = dy + 1;
            end
            value = z(:, idx);
        end
        %% curvature hint energy
        function sum_energy = energy(z, z_model, edges)
            S = 0;
            for i = 1:size(pt2d, 2)
                S = S + (getZneighbor(z, i, 1, 0, edges) -  2*getZneighbor(z, i, 0, 0, edges) + getZneighbor(z, i, -1, 0, edges))^2 +...
                    (getZneighbor(z, i, -1, -1, edges) - getZneighbor(z, i, -1, 1, edges) - getZneighbor(z, i, 1, -1, edges) + getZneighbor(z, i, 1, 1, edges))^2/8 +...
                    (getZneighbor(z, i, 1, 0, edges) - 2*getZneighbor(z, i, 0, 0, edges) + getZneighbor(z, i, -1, 0, edges) )^2;
                C = (getZneighbor(z, i, 1, 0, edges) -  2*getZneighbor(z, i, 0, 0, edges) + getZneighbor(z, i, -1, 0, edges)) +...
                    (getZneighbor(z, i, -1, -1, edges) - getZneighbor(z, i, -1, 1, edges) - getZneighbor(z, i, 1, -1, edges) + getZneighbor(z, i, 1, 1, edges))/2 +...
                    (getZneighbor(z, i, 1, 0, edges) - 2*getZneighbor(z, i, 0, 0, edges) + getZneighbor(z, i, -1, 0, edges) );

            end
            R = sum(z - z_model).^2;
                
            sum_energy = S + R + C;
        end
        %%
        %z mxn ?
        function sum_grad = computeGrad(z)
            S_grad = 25*getZneighbor(z, i, 1, 0, edges) + 3/2*(getZneighbor(z, i, 0, 2, edges) + getZneighbor(z, i, 0, -2, edges) + getZneighbor(z, i, 2, 0, edges) + getZneighbor(z, i, -2, 0, edges)) -...
                8*(getZneighbor(z, i, 1, 0, edges) + getZneighbor(z, i, -1, 0, edges) + getZneighbor(z, i, 0, 1, edges) + getZneighbor(z, i, 0, -1, edges)) +...
                (getZneighbor(z, i, 2, 2, edges) + getZneighbor(z, i, 2, -2, edges)+ getZneighbor(z, i, -2, -2, edges) + getZneighbor(z, i, -2, 2, edges))/4;
            R_grad = 25*getZneighbor(z, i, 0, 0, edges) +...
                3/2*(getZneighbor(z, i, 0, 2, edges) + getZneighbor(z, i, 0, -2, edges) + getZneighbor(z, i, 2, 0, edges) + getZneighbor(z, i, -2, 0, edges)) -...
                8*(getZneighbor(z, i, 1, 0, edges) + getZneighbor(z, i, -1, 0, edges) + getZneighbor(z, i, 0, 1, edges) + getZneighbor(z, i, 0, -1, edges)) +...
                (getZneighbor(z, i, 2, 2, edges) + getZneighbor(z, i, 2, -2, edges)+ getZneighbor(z, i, -2, -2, edges) + getZneighbor(z, i, -2, 2, edges))/4;
            C_grad = 0;
            sum_grad = 0;
        end
    end
    
end