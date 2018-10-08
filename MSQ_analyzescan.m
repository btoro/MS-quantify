function MSQ_analyzescan()

%Select directory than contains all mzXML files, and config files
directory = 'data';

currdir = cd;

cd(directory)

interpretScans();






%Return to main directory
cd(currdir)





end

function interpretScans()
    %%
    % Removes previously openned figures :D  
    delete(findall(0,'Type','figure'))
    clear output
    
    disp(pwd)

    
    flist=dir('*.skip');

    if isempty(flist)

        flist=subdir('*.mzXML'); % looks for local mzXML files
        if ~isempty(flist)

            for i = 1:length(flist)
                name = strsplit(flist(i).name, '.');

                fprintf('\n\nAnalyzing file #%d -> %s\n\n',i,name{1});

                %Load mat file if already exists. Scans dont change and it saves a lot
                %of time.
               mz_file_path = sprintf('%s_ms.mat', name{1});
                
                if exist( mz_file_path, 'file')
                    load(mz_file_path);
                else          
                    
                    fprintf('Importing file %s # %d',name{1}, i);
                    raw = mzxmlread(flist(i).name);
                    
                    massspec = struct();
                    
                    for j = 1:length(raw.scan)
                        massspec(j).scan = [raw.scan(j).peaks.mz(1:2:end),raw.scan(j).peaks.mz(2:2:end)];
                        massspec(j).TIC = raw.scan(j).totIonCurrent;
                    end
                    
                    save( mz_file_path, 'massspec' );
                end


                %Region Loading
                regions = loadRegions( 'regions.ini');
                
                %Analysis 
                len = length(massspec);
                
                
                auc = cell(len,1);

                for j = 1:len

                    fprintf('\n\nAnalyzing Scan #%d/%d of file %s \n\n',j,len, name{1} );
                    
                    rauc = calcAUC( massspec(j).scan(:,1), massspec(j).scan(:,2), regions );

                    auc{j} = rauc;
                    
                end          
                
                % Store AUC Data
                meta_file_path = sprintf('%s_auc.mat', name{1});
                save( meta_file_path, 'auc' );

            end
            disp('Imported and analyzed all files in directory.');
            
        end
    end
end

%Loads Region ini file
function [ regions ] = loadRegions( filename )
    
    regions = struct();


    ini = IniConfig();
    ini.ReadFile(filename);
    
    sections = ini.GetSections();
    
    n = 1;

    for i = 1:length(sections)
        
        [keys, ~] = ini.GetKeys(sections{i});
        values = ini.GetValues(sections{i}, keys);
        
        sec = strrep(sections{i}, '[', '');
        sec = strrep(sec, ']', '');        

        for j = 1:length(values)
            
            regions(n).name = sec;
            regions(n).charge = values{j}(1);
            regions(n).range = values{j}(2:3);
            
            n = n+1;
        end

    end
    
    fprintf('Loaded Regions Succesfully.\n');
end


%%Calculate AUC
function [auc] = calcAUC(MZ, Y, regions )

    auc = struct();
    
    % Loop thorugh each region
    for i = 1:length(regions)
        
        fprintf('Analyzing %s with a charge of -%d \n', regions(i).name, regions(i).charge );
        
        %Isolate Scan into region
        indice = find( MZ < regions(i).range(2) & MZ > regions(i).range(1)); 
        MZ_region = MZ(indice);
        Int_region = Y(indice);
        
        %Actual AUC Function
        if length(MZ_region) > 1
            AUC_a = trapz(MZ_region, Int_region)/regions(i).charge;
        else
            AUC_a = 0;
        end
        
        %Store AUC & Peak
        auc(i).name = regions(i).name;
        auc(i).region = i;
        auc(i).charge = regions(i).charge;
        auc(i).type = 1;
        auc(i).mz = regions(i).range;
        auc(i).auc = AUC_a;    
    end
end