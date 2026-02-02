function sess_datas = divide_into_sessions(data)
% Takes a dataset and divides it up into individual sessions

if isempty(data)
    sess_datas = [];
    return
end

nTrials = data.nTrials;

% Get a list of the session start and end indices
sess_start_inds = find(data.new_sess);
sess_end_inds = [sess_start_inds(2:end)-1, nTrials]; % Session ends are one before all starts other than the first one, as well as the last trial in the data

nSess = length(sess_start_inds);
sess_datas = cell(1,nSess);

% Get a list of the field names
fnames = fieldnames(data);
nFields = length(fnames);

% Loop through sessions, fieldnames
for sess_i = 1:nSess
    sess_start_ind = sess_start_inds(sess_i);
    sess_end_ind = sess_end_inds(sess_i);
    sess_inds = sess_start_ind:sess_end_ind;
    
    for field_i = 1:nFields
        field_name = fnames{field_i};
        field_data = getfield(data, field_name);
        
        if length(field_data) == nTrials % This is a field we should parse into sessions
            field_data_sub = field_data(sess_inds);
            sess_datas{sess_i} = setfield(sess_datas{sess_i},field_name,field_data_sub);
        elseif strcmp(field_name,'values')
            fnames_val = fieldnames(mousedata.values);
            values = struct;
            for valfield_i = 1:length(fnames_val)
                fname_val = fnames_val{valfield_i};
                valdata = getfield(data.values,fname_val);
                if size(valdata,1) == nTrials
                    valdata_sub = valdata(sess_inds,:);
                    values = setfield(values,fname_val,valdata_sub);
                end
            end
            sess_datas{sess_i} = setfield(sess_datas{sess_i},'values',values);
        else % This field does not contain trial-by-trial data - just copy it
            sess_datas{sess_i} = setfield(sess_datas{sess_i},field_name,field_data);
        end
        
    end
    
    % Now let's handle the nTrials field
    sess_datas{sess_i} = setfield(sess_datas{sess_i},'nTrials',length(sess_datas{sess_i}.choices));
end

end