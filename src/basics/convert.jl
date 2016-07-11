macro ArbFloat(x)
    convert(ArbFloat, string(:($x)))
end
macro ArbFloat(p,x)
    convert(ArbFloat{:($p)}, string(:($x)))
end

# interconvert Arb with Arf

function convert{P}(::Type{ArbFloat{P}}, x::ArfFloat{P})
    z = initializer(ArbFloat{P})
    ccall(@libarb(arb_set_arf), Void, (Ptr{ArbFloat{P}}, Ptr{ArfFloat{P}}), &z, &x)
    z
end

function convert{P}(::Type{ArfFloat{P}}, x::ArbFloat{P})
    z = initializer(ArfFloat{P})
    z.exponent  = x.exponent
    z.words_sgn = x.words_sgn
    z.mantissa1   = x.mantissa1
    z.mantissa2   = x.mantissa2
    z
end

#interconvert ArbFloat{P} with ArbFloat{Q}

function convert{P,Q}(::Type{ArbFloat{Q}}, a::ArbFloat{P})
    if (Q < P)
        a = round(a, Q, 2)
    end

    z = initializer(ArbFloat{Q})
    z.exponent  = a.exponent
    z.words_sgn = a.words_sgn
    z.mantissa1   = a.mantissa1
    z.mantissa2   = a.mantissa2
    z.radiusExp  = a.radiusExp
    z.radiusMan  = a.radiusMan

    z
end

#

function convert{P}(::Type{ArbFloat{P}}, x::UInt)
    z = initializer(ArbFloat{P})
    ccall(@libarb(arb_set_ui), Void, (Ptr{ArbFloat{P}}, UInt), &z, x)
    z
end
if sizeof(Int)==sizeof(Int64)
   convert{P}(::Type{ArbFloat{P}}, x::UInt32) = convert(ArbFloat{P}, convert(UInt64,x))
else
   convert{P}(::Type{ArbFloat{P}}, x::UInt64) = convert(ArbFloat{P}, convert(UInt32,x))
end
convert{P}(::Type{ArbFloat{P}}, x::UInt16) = convert(ArbFloat{P}, convert(UInt,x))

function convert{P}(::Type{ArbFloat{P}}, x::Int)
    z = initializer(ArbFloat{P})
    ccall(@libarb(arb_set_si), Void, (Ptr{ArbFloat{P}}, Int), &z, x)
    z
end
if sizeof(Int)==sizeof(Int64)
   convert{P}(::Type{ArbFloat{P}}, x::Int32) = convert(ArbFloat{P}, convert(Int64,x))
else
   convert{P}(::Type{ArbFloat{P}}, x::Int64) = convert(ArbFloat{P}, convert(Int32,x))
end
convert{P}(::Type{ArbFloat{P}}, x::Int16) = convert(ArbFloat{P}, convert(Int,x))


function convert{P}(::Type{ArbFloat{P}}, x::Float64)
    z = initializer(ArbFloat{P})
    fp=copy(x)
    ccall(@libarb(arb_set_d), Void, (Ptr{ArbFloat{P}}, Float64), &z, fp)
    z
end
convert{P}(::Type{ArbFloat{P}}, x::Float32) = convert(ArbFloat{P}, convert(Float64,x))
convert{P}(::Type{ArbFloat{P}}, x::Float16) = convert(ArbFloat{P}, convert(Float64,x))


function convert{P}(::Type{ArbFloat{P}}, x::String)
    s = String(x)
    z = initializer(ArbFloat{P})
    ccall(@libarb(arb_set_str), Void, (Ptr{ArbFloat}, Ptr{UInt8}, Int), &z, s, P)
    z
end


convert(::Type{BigInt}, x::String) = parse(BigInt,x)
convert(::Type{BigFloat}, x::String) = parse(BigFloat,x)

function convert{P}(::Type{ArbFloat{P}}, x::BigFloat)
     x = round(x,P,2)
     s = string(x)
     ArbFloat{P}(s)
end

function convert{P}(::Type{BigFloat}, x::ArbFloat{P})
     s = smartarbstring(x)
     parse(BigFloat, s)
end

function convert{I<:Integer,P}(::Type{Rational{I}}, x::ArbFloat{P})
    bf = convert(BigFloat, x)
    convert(Rational{I}, bf)
end

convert{P}(::Type{ArbFloat{P}}, x::BigInt)   = convert(ArbFloat{P}, convert(BigFloat,x))
convert{P}(::Type{ArbFloat{P}}, x::Rational) = convert(ArbFloat{P}, convert(BigFloat,x))
convert{P,S}(::Type{ArbFloat{P}}, x::Irrational{S}) =
    convert(ArbFloat{P}, convert(BigFloat,x))



convert{P}(::Type{ArbFloat{P}}, y::ArbFloat{P}) = y

for T in (:Float64, :Float32)
  @eval begin
    function convert{P}(::Type{$T}, x::ArbFloat{P})
      s = smartarbstring(x)
      try
          parse(($T), s)
      catch
          throw(DomainError)
      end
    end
  end
end

function convert{P}(::Type{BigInt}, x::ArbFloat{P})
   z = convert(BigFloat, x)
   return convert(BigInt, z)
end
for T in (:Int128, :Int64, :Int32, :Int16)
  @eval begin
    function convert{P}(::Type{$T}, x::ArbFloat{P})
      z = convert(BigInt, x)
      return convert(($T), z)
    end
  end
end



#=
function convert{I<:Integer,P}(::Type{I}, x::ArbFloat{P})
    s = smartarbstring(x)
    parse(I,split(s,".")[1])
end
=#

for T in (:Int128, :Int64, :Int32, :Int16, :Float64, :Float32, :Float16,
          :(Rational{Int64}), :(Rational{Int32}), :(Rational{Int16}),
          :String)
  @eval convert(::Type{ArbFloat}, x::$T) = convert(ArbFloat{precision(ArbFloat)}, x)
end


# Promotion
for T in (:Int128, :Int64, :Int32, :Int16, :Float64, :Float32, :Float16,
          :(Rational{Int64}), :(Rational{Int32}), :(Rational{Int16}),
          :String)
  @eval promote_rule{P}(::Type{ArbFloat{P}}, ::Type{$T}) = ArbFloat{P}
end

promote_rule{P}(::Type{ArbFloat{P}}, ::Type{BigFloat}) = BigFloat
promote_rule{P}(::Type{ArbFloat{P}}, ::Type{BigInt}) = ArbFloat{P}
promote_rule{P}(::Type{ArbFloat{P}}, ::Type{Rational{BigInt}}) = Rational{BigInt}

promote_rule{P,Q}(::Type{ArbFloat{P}}, ::Type{ArbFloat{Q}}) =
    ifelse(P>Q, ArbFloat{P}, ArbFloat{Q})
