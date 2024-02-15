module ZarrDatasets

import Base:
    checkbounds,
    getindex,
    setindex!,
    size

import CommonDataModel:
    CFVariable,
    SymbolOrString,
    attrib,
    attribnames,
    dataset,
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
    haschunks

import CommonDataModel as CDM
using DataStructures
using Zarr

include("types.jl")
include("dataset.jl")
include("variable.jl")

export ZarrDataset
end
