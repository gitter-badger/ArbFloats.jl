#=
#define FMPR_RND_DOWN  0    RoundingMode{:Down}()
#define FMPR_RND_UP    1
#define FMPR_RND_FLOOR 2
#define FMPR_RND_CEIL  3
#define FMPR_RND_NEAR  4
=#

sigBitsToUse(prec::Int, sig::Int, base::Int) =
    min(prec, ifelse(signbit(sig), -sig, sig) * log2(base))

function round{P}(x::ArbFloat{P}, sig::Int=P, base::Int=10)
    sigbits = sigBitsToUse(P, sig, base)
    z = initializer(ArbFloat{P})
    ccall(@libarb(arb_set_round), Void,  (Ptr{ArbFloat}, Ptr{ArbFloat}, Int), &z, &x, sigbits)
    return z
end

function ceil{P}(x::ArbFloat{P}, sig::Int=P, base::Int=10)
    sigbits = sigBitsToUse(P, sig, base)
    z = initializer(ArbFloat{P})
    ccall(@libarb(arb_ceil), Void,  (Ptr{ArbFloat}, Ptr{ArbFloat}, Int), &z, &x, sigbits)
    return z
end

function floor{P}(x::ArbFloat{P}, sig::Int=P, base::Int=10)
    sigbits = sigBitsToUse(P, sig, base)
    z = initializer(ArbFloat{P})
    ccall(@libarb(arb_floor), Void,  (Ptr{ArbFloat}, Ptr{ArbFloat}, Int), &z, &x, sigbits)
    return z
end

function trunc{P}(x::ArbFloat{P}, sig::Int=P, base::Int=10)
    sigbits = sigBitsToUse(P, sig, base)
    z = initializer(ArbFloat{P})
    if signbit(x)
        ccall(@libarb(arb_ceil), Void,  (Ptr{ArbFloat}, Ptr{ArbFloat}, Int), &z, &x, sigbits)
    else
        ccall(@libarb(arb_floor), Void,  (Ptr{ArbFloat}, Ptr{ArbFloat}, Int), &z, &x, sigbits)
    end
    return z
end

function round{I<:Integer,P}(::Type{I}, x::ArbFloat{P}, sig::Int=P, base::Int=10)
    z = round(x, sig, base)
    return convert(I, z)
end
function ceil{I<:Integer,P}(::Type{I}, x::ArbFloat{P}, sig::Int=P, base::Int=10)
    z = ceil(x, sig, base)
    return convert(I, z)
end
function floor{I<:Integer,P}(::Type{I}, x::ArbFloat{P}, sig::Int=P, base::Int=10)
    z = floor(x, sig, base)
    return convert(I, z)
end
function trunc{I<:Integer,P}(::Type{I}, x::ArbFloat{P}, sig::Int=P, base::Int=10)
    z = trunc(x, sig, base)
    return convert(I, z)
end


fld{P}(x::ArbFloat{P}, y::ArbFloat{P}) = convert(Int, floor(x/y))
cld{P}(x::ArbFloat{P}, y::ArbFloat{P}) = convert(Int, ceil(x/y))
div{P}(x::ArbFloat{P}, y::ArbFloat{P}) = convert(Int, trunc(x/y))

rem{P}(x::ArbFloat{P}, y::ArbFloat{P}) = convert(Int, x - div(x,y)*y)
mod{P}(x::ArbFloat{P}, y::ArbFloat{P}) = convert(Int, x - fld(x,y)*y)

function divrem{P}(x::ArbFloat{P}, y::ArbFloat{P})
   dv = div(x,y)
   r  = x - d*y
   rm = convert(Int, r)
   return dv,rm
end

function fldmod{P}(x::ArbFloat{P}, y::ArbFloat{P})
   fd = fld(x,y)
   m  = x - d*y
   md = convert(Int, m)
   return fd,md
end

