module ZarrDatasets

import Base:
    checkbounds,
    size

import CommonDataModel:
    CFVariable,
    MFDataset,
    SymbolOrString,
    attrib,
    attribnames,
    dataset,
    defAttrib,
    defVar,
    defDim,
    defGroup,
    dim,
    dimnames,
    iswritable,
    load!,
    maskingvalue,
    name,
    parentdataset,
    variable

import DiskArrays:
    eachchunk,
    haschunks,
    readblock!,
    writeblock!

import CommonDataModel as CDM
using DataStructures
using ZarrCore

export ZarrDataset
export defDim, defVar, defGroup

include("types.jl")
include("dataset.jl")
include("variable.jl")

end
