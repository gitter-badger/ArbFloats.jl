@inline digitsRequired(bitsOfPrecision) = ceil(Int, bitsOfPrecision*0.3010299956639811952137)

function string{P}(x::ArbFloat{P}, ndigits::Int, flags::UInt)
    n = max(1,min(abs(ndigits), digitsRequired(P)))
    cstr = ccall(@libarb(arb_get_str), Ptr{UInt8}, (Ptr{ArbFloat}, Int, UInt), &x, n, flags)
    s = unsafe_string(cstr)
    ccall(@libflint(flint_free), Void, (Ptr{UInt8},), cstr)
    if !isinteger(x)
        s = rstrip(s, '0')
        if s[end]=='.'
            s = string(s, "0")
        end
    else
        s = String(split(s, '.')[1])
    end
    return s
end

function String{P}(x::ArbFloat{P}, flags::UInt)
    cstr = ccall(@libarb(arb_get_str), Ptr{UInt8}, (Ptr{ArbFloat}, Int, UInt),
                 &x, digitsRequired(P), flags)
    s = unsafe_string(cstr)
    ccall(@libflint(flint_free), Void, (Ptr{UInt8},), cstr)
    if !isinteger(x)
        s = rstrip(s, '0')
        if s[end]=='.'
            s = string(s, "0")
        end
    else
        s = String(split(s, '.')[1])
    end
    return s
end

# n=trunc(abs(log(upperbound(x)-lowerbound(x))/log(2))) just the good bits
function string{P}(x::ArbFloat{P}, ndigits::Int)
    s = string(x, ndigits, UInt(2)) # midpoint only (within 1ulp), RoundNearest
    return s
end

# n=trunc(abs(log(upperbound(x)-lowerbound(x))/log(2))) just the good bits
function string{P}(x::ArbFloat{P})
    s = String(x,UInt(2)) # midpoint only (within 1ulp), RoundNearest
    return s
end

function stringTrimmed{P}(x::ArbFloat{P}, ndigitsremoved::Int)
   n = max(1, digitsRequired(P) - max(0, ndigitsremoved))
   cstr = ccall(@libarb(arb_get_str), Ptr{UInt8}, (Ptr{ArbFloat}, Int, UInt), &x, n, UInt(2))
   s = unsafe_string(cstr)
   ccall(@libflint(flint_free), Void, (Ptr{UInt8},), cstr)
   s
end

#=
     find the smallest N such that stringTrimmed(lowerbound(x), N) == stringTrimmed(upperbound(x), N)
=#

function smartarbstring{P}(x::ArbFloat{P})
     digits = digitsRequired(P)
     if isexact(x)
        if isinteger(x)
            return string(x, digits, UInt(2))
        else
            s = rstrip(string(x, digits, UInt(2)),'0')
            if s[end]=='.'
               s = string(s, "0")
            end
            return s
        end
     end
     if radius(x) > abs(midpoint(x))
        return "0"
     end

     lb, ub = bounds(x)
     lbs = string(lb, digits, UInt(2))
     ubs = string(ub, digits, UInt(2))
     if lbs[end]==ubs[end] && lbs==ubs
         return ubs
     end
     for i in (digits-2):-2:4
         lbs = string(lb, i, UInt(2))
         ubs = string(ub, i, UInt(2))
         if lbs[end]==ubs[end] && lbs==ubs # tests rounding to every other digit position
            us = string(ub, i+1, UInt(2))
            ls = string(lb, i+1, UInt(2))
            if us[end] == ls[end] && us==ls # tests rounding to every digit position
               ubs = lbs = us
            end
            break
         end
     end
     if lbs != ubs
        ubs = string(x, 3, UInt(2))
     end
     rstrip(ubs,'0')
end

function smartvalue{P}(x::ArbFloat{P})
    s = smartarbstring(x)
    ArbFloat{P}(s)
end

function smartstring{P}(x::ArbFloat{P})
    s = smartarbstring(x)
    a = ArbFloat{P}(s)
    if notexact(x)
       s = string(s,upperbound(x) < a ? '-' : (lowerbound(x) > a ? '+' : '~'))
    end
    return s
end

function smartstring{T<:ArbFloat}(x::T)
    absx   = abs(x)
    sa_str = smartarbstring(absx)  # smart arb string
    sa_val = (T)(absx)             # smart arb value
    if notexact(absx)
        md,rd = midpoint(absx), radius(absx)
        lo,hi = bounds(absx)
        if     sa_val <= lo
            if lo-sa_val >= ufp2(rd)
                sa_str = string(sa_str,"⁺")
            else
                sa_str = string(sa_str,"₊")
            end
        elseif sa_val > hi
            if sa_val-hi >= ufp2(rd)
                sa_str = string(sa_str,"⁻")
            else
                sa_str = string(sa_str,"₋")
            end
        else
            sa_str = string(sa_str,"~")
        end
    end
    return sa_str
end

function stringall{P}(x::ArbFloat{P})
    return (isexact(x) ? string(midpoint(x)) :
              string(midpoint(x)," ± ", string(radius(x),10)))
end

function stringcompact{P}(x::ArbFloat{P})
    string(x,8)
end

function stringallcompact{P}(x::ArbFloat{P})
    return (isexact(x) ? string(midpoint(x)) :
              string(string(midpoint(x),8)," ± ", string(radius(x),10)))
end

