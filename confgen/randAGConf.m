function dom = randAGConf(nmodel, texturePath)
% RANDAGCONF generate random configuration file in DOM format
%
% USAGE: DOM = RANDAGCONF(NMODEL, TEXTUREPATH) generate a configuration
%              with NMODELS, and point texture library to the path
%              specified by TEXTUREPATH
%
% MooGu Z. <hzhu@case.edu>
% 2015.04.22 - Version 0.00

% content number utilized in this function
MINRADIUS = 3;
MAXRADIUS = 10;
MAXCURVATURE = 5;
MAXGAUSSHEIGHT = 5;
AREACENTER = [0,0,9];
AREARANGE = 5;
MINVELOCITY = 1;
MAXVELOCITY = 5;
MINANGLEV = 15;
MAXANGLEV = 360;

% set of symmetic, curve, and trajectory types
symSet  = {'plane', 'axis'};
curfSet = {'Gaussian', 'Sphere', 'Circle', 'Rectangle'};
trajSet = {'line', 'rotate', 'approach', 'shift'};

% initialize a DOM object
dom = com.mathworks.xml.XMLUtils.createDocument('config');

% get root node
rootNode = dom.getDocumentElement;
% set configuation name by current time
rootNode.setAttribute('name', datestr(now));

% check path of texture files
assert(7 == exist(texturePath,'file'), ...
    'TEXTUREPATH (2nd input argument) should be a valid directory');
% get file list under texture path
flist = dir(texturePath);
% check each file to find images
idx = boolean(zeros(1, numel(flist)));
for i = 1 : numel(flist)
    [~,~,ext] = fileparts(flist(i).name);
    if any(strcmpi(ext, {'.png', '.jpg', '.jpeg', '.bmp', '.gif'}))
        idx(i) = true;
    end
end
% filter the non-images out
flist = {flist(idx).name};

% initialize texture list
textureSet = cell(1, numel(flist));

% read each image and create corresponding texture node for it
for i = 1 : numel(flist)
    textureNode = dom.createElement('texture');
    % set texture name by file name and record it to texture list
    [~, tname, ~] = fileparts(flist{i});
    textureNode.setAttribute('name', upper(tname));
    textureSet{i} = upper(tname);
    % set content as file path
    textureNode.setTextContent(fullfile(abspath(texturePath),flist{i}));
    % add texture node to the configuration tree
    rootNode.appendChild(textureNode);
end

% define a helper functions
chooseOne = @(S) S{ceil(rand() * numel(S))};
normvec = @(vec) vec / norm(vec(:));
randDirection = @() normvec(randn(1,3));
randPosition = @(center, radius) ...
    center + randDirection() * rand() * radius;
randPositive = @(lowBound, upBound) ...
    lowBound + (upBound - lowBound) * rand();

% creat NMODEL model nodes randomly
for i = 1 : nmodel
    modelNode = dom.createElement('model');
    % set model name as RANDOM-<#>
    modelNode.setAttribute('name', sprintf('RANDOM-%d', i));
    
    % generate surface node
    % ---------------------
    % create surface branch
    surfNode = dom.createElement('surface');
    % randomly set surface curve type
    curvType = chooseOne(curfSet);
    surfNode.setAttribute('type', curvType);
    % add common fields for all curve type
    surfPosition = randPosition(AREACENTER, AREARANGE);
    addChildNode(dom, surfNode, 'position', surfPosition);
    addChildNode(dom, surfNode, 'normal', randDirection());
    % create surface configuration according to surface type
    switch curvType
        case 'Gaussian'
            symType = chooseOne(symSet);
            addChildNode(dom, surfNode, 'curvature', ...
                chooseOne({-1.0,1.0}) * randPositive(0, MAXCURVATURE));
            addChildNode(dom, surfNode, 'height', ...
                randPositive(0, MAXGAUSSHEIGHT));
            addChildNode(dom, surfNode, 'radius', ...
                randPositive(MINRADIUS, MAXRADIUS));
            
        case 'Sphere'
            symType = chooseOne(symSet);
            addChildNode(dom, surfNode, 'curvature', ...
                chooseOne({-1.0,1.0}) * randPositive(0, MAXCURVATURE));
            addChildNode(dom, surfNode, 'angle', ...
                chooseOne({pi/4, pi/2, 3/4 * pi, pi}));
            
        case 'Circle'
            symType = 'axis';
            addChildNode(dom, surfNode, 'radius', ...
                randPositive(MINRADIUS, MAXRADIUS));
            
        case 'Rectangle'
            symType = 'axis';
            addChildNode(dom, surfNode, 'width', ...
                randPositive(MINRADIUS, MAXRADIUS));
            addChildNode(dom, surfNode, 'height', ...
                randPositive(MINRADIUS, MAXRADIUS));
            addChildNode(dom, surfNode, 'orient', randPositive(0, 360));
            
        otherwise
            error('Unrecognized Curve Type : %s\n', curvType);
    end
    % set symmetric type of current surface
    surfNode.setAttribute('sym', symType);
    % add symmetric type related fields
    switch symType
        case 'axis'
            % empty, no extra field is needed in radian-symmetric
            
        case 'plane'
            addChildNode(dom, surfNode, 'orient', randPositive(0, 360));
            addChildNode(dom, surfNode, 'symrange', ...
                randPositive(MINRADIUS, MAXRADIUS));
            
        otherwise
            error('Unrecognized Symmetric Type : %s\n', symType);
    end
    % add texture field
    addChildNode(dom, surfNode, 'texture', chooseOne(textureSet));
    % append surface node to model
    modelNode.appendChild(surfNode);
    
    % generate camera node
    % --------------------
    % create camera branch
    camNode = dom.createElement('camera');
    % create animation branch
    animNode = dom.createElement('animation');
    % randomly set camera position
    addChildNode(dom, animNode, 'eye', ...
        randPosition(AREACENTER, AREARANGE));
    % set target to the position of surface
    addChildNode(dom, animNode, 'target', surfPosition);
    % set up direction to [0,0,1]
    addChildNode(dom, animNode, 'up', [0,0,1]);
    % set trajectory type
    trajType = chooseOne(trajSet);
    animNode.setAttribute('trajectory', trajType);
    % add fields according to trajectory type
    switch trajType
        case 'shift'
            addChildNode(dom, animNode, 'direction', randDirection());
            addChildNode(dom, animNode, 'velocity', ...
                randPositive(MINVELOCITY, MAXVELOCITY));
            
        case 'approach'
            addChildNode(dom, animNode, 'velocity', ...
                randPositive(MINVELOCITY, MAXVELOCITY));
            
        case 'rotate'
            addChildNode(dom, animNode, 'velocity', ...
                randPositive(MINANGLEV, MAXANGLEV));
            
        case 'line'
            addChildNode(dom, animNode, 'direction', randDirection());
            addChildNode(dom, animNode, 'velocity', ...
                randPositive(MINVELOCITY, MAXVELOCITY));
            
        otherwise
            error('Unrecognized Trajectory Type : %s\n', trajType);
    end
    % append animation node to camera node
    camNode.appendChild(animNode);
    % append camera node to model node
    modelNode.appendChild(camNode);
    
    % add model node to the configuration tree
    rootNode.appendChild(modelNode);
end

end

function fullp = abspath(p)
% a help function to get absolute path
%
% USAGE : FULLP = ABSPATH(P)
%
% MooGu Z. <hzhu@case.edu>
% Apr 23, 2015 - Version 0.00

if p(1) == '.'
    curdir = pwd; cd(p);
    fullp  = pwd; cd(curdir);
else
    fullp = p;
end

end

function childNode = addChildNode(DOM, parentNode, name, value)
% CREATECHILDNODE is a helper function as a shortcut to create a child node
% to current node (PARENTNODE) under current document object (DOM) with
% node name NAME and get content by value calculate function (VFUNC)
%
% USAGE: CHILDNODE = CREATECHILDNODE(DOM, PARENTNODE, NAME, VFUNC)
%
% MooGu Z. <hzhu@case.edu>
% Apr 23, 2015 - Version 0.00

% helper anonymous function to generate pretty array string
arr2str = @(arr) ['[',regexprep(num2str(arr), '\s+', ','),']'];

% create child branch
childNode = DOM.createElement(name);
% process the value to text information
if ~ischar(value)
    if numel(value) > 1
        value = arr2str(value);
    else
        value = num2str(value);
    end
end
% set content value of parent node
childNode.setTextContent(value);
% attach child node to parent node
parentNode.appendChild(childNode);

end
