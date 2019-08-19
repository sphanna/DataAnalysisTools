module DataAnalysisTools

using LsqFit, Plots
import LsqFit: curve_fit
export modify,crop,mask,plotData!,modelWeights,analyze

function modify(data; xfunc = x->x, yfunc = y->y)
    xdat = data[1]; ydat = data[2]
    if length(data) > 2
        ydatm = ydat .± data[3]
    else
        ydatm = measurement().(ydat)
    end

    xdat = map(xfunc,xdat)
    ydatm = map(yfunc,ydatm)
    yvals = map(y->y.val,ydatm)
    yerrs = map(y->y.err,ydatm)

    return [x,yvals,yerrs]
end

#Keeps only data within xmin,xmax and within ymin,ymax
function crop(data; xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf)
    x = data[1]; y = data[2];
    xindices = findall(sx->sx .>= xmin && sx .<= xmax,x)
    yindices = findall(sy->sy .>= ymin && sy .<= ymax,y)
    newindices = intersect(xindices,yindices)
    xnew = x[newindices]
    ynew = y[newindices]
    newdata = [xnew,ynew]
    if length(data) > 2
        err = data[3]
        push!(newdata,err[newindices])
    end
    return newdata
end

#Removes all data within xmin,xmax and within ymin,ymax
function mask(data; xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf)
    x = data[1]; y = data[2];
    xindices = findall(sx->sx .< xmin && sx .> xmax,x)
    yindices = findall(sy->sy .< ymin && sy .> ymax,y)
    newindices = union(xindices,yindices)
    xnew = x[newindices]
    ynew = y[newindices]
    newdata = [xnew,ynew]
    if length(data) > 2
        err = data[3]
        push!(newdata,err[newindices])
    end
    return newdata
end

function plotData!(plt,data;kwargs...)
    x = data[1]; y = data[2]
    if length(data) < 3
        Plots.plot!(plt, x,y;kwargs...)
    else
        yerr = data[3]
        Plots.plot!(plt, x,y .± yerr;kwargs...)
    end
end

function modelWeights(data)
    weights = ones(length(data[1]))
    if length(data) > 2
        weights = (1 ./ (data[3].^2))
    end
end

function analyze(data,model)
    x,y,yerr = data
    weights = modelWeights(data)
    #fitting
    fit = curve_fit(model,x,y,weights,[1.0,1.0])
    modely = model(x,fit.param)
    modelData = [x,modely]
    sigma = stderror(fit)
    params = fit.param .± sigma

    return [params,modelData]
end

end #module DataAnalysisTools
