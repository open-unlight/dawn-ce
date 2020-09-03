# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'digest/sha1'
require 'gmp'

# SRPクラス
# http://srp.stanford.edu/design.htmlを参照
class SRP

  # イニシャライズ
  def initialize(n=nil,g=nil,s=nil)
    @N = n ||"115b8b692e0e045692cf280b436735c77a5a9e8a9e7ed56c965f87db5b2a2ece3".hex
    @g = g ||2
    # プロトコル設定
    @proto = s ||:'SPR6a'            # SPR3 or SPR6 or SPR6a
    @k = srp_compute_k(@N,@g)
    tn =@N.to_s(16)
    if tn.length&1==1
      tn="0"+tn
    end
    @m = hex2array(sha1_hash_hex(tn))^hex2array(sha1_hash_hex(@g.to_s(16)))
    srp_validate_g(@g) if g
  end

  # Private Keyを取得（hex)
  def get_private_key(username,password,salt)
    srp_compute_x(username, password, salt).to_s(16)
  end

  # verifierを取得（hex)
  def get_verifier(private_key)
    srp_compute_v(private_key.hex).to_s(16)
  end

  # サーバ公開鍵を取得（hex)
  def get_server_public_key(rnd_num,verifier)
    srp_compute_B(rnd_num.hex,verifier.hex).to_s(16)
  end

  # セッション鍵を取得（hex)
  def get_session_key(c_p_key, s_p_key, verifier, rand_num)
    srp_compute_server_S(c_p_key.hex, verifier.hex, srp_compute_u(c_p_key,s_p_key).hex, rand_num.hex).to_s(16)
  end

  # ストロングセッション鍵を取得（hex)
  def get_strong_key(session_key)
    sha1_hash_hex(session_key)
 end

  # 認証
  def get_matcher(c_p_key, s_p_key,username,salt,strong_key)
    sha1_hash_hex(array2hex(@m)+Digest::SHA1.hexdigest(username)+salt+c_p_key+s_p_key+strong_key)
  end

  # 証明
  def get_cert(c_p_key,matcher,strong_key)
     sha1_hash_hex(c_p_key+matcher+strong_key)
  end

  def rand_hex
    a = ''
    a << Time.now.to_s
    a << rand(1000).to_s
    a << "takuramakuran"
    ret = Digest::SHA1.hexdigest(a)
    ret
  end

  def srp_compute_x(u, p, s)
    ih=Digest::SHA1.hexdigest(u+":"+p)
    oh=sha1_hash_hex(s+ih).hex
    if oh < @N
      oh
    else
      oh%(@N-1)
    end
  end

   def srp_compute_u(ahex,bhex)
     hashin=''
     if @proto != :'SPR3'
       if @proto == :'SPR6'
         if ((ahex.length&1)==0)
           hashin += ahex
         else
           hashin +="0" +ahex
         end
       else
         nlen =2*((@N.to_s(2).length+7)>>3)
         hashin += nzero(nlen-ahex.length)+ahex
       end
     end
     if (@proto == :'SPR3' || @proto == :'SPR6')
       if((bhex.length & 1) == 0)
         hashin += bhex
       else
         hashin += "0" + bhex
       end
     else
       hashin += nzero(nlen - bhex.length) + bhex
     end
    if(@proto == :"SPR3")
       utmp = sha1_hash_hex(hashin)[0,8]
    else
       utmp = sha1_hash_hex(hashin)
    end
    if utmp.hex < @N
      utmp
    else
      utmp.hex%(@N-1)
    end
  end

  def srp_compute_k(n, g)
    hashin = ""
    if @proto == :'SPR3'
      1
    elsif @proto == :'SPR6'
      3
    else
      nhex = n.to_s(16)
      if((nhex.length & 1) == 0)
        hashin += nhex
      else
        hashin += "0" + nhex
      end
      ghex = g.to_s(16)
      hashin += nzero(nhex.length - ghex.length);
      hashin += ghex;
      ktmp = sha1_hash_hex(hashin)
      if ktmp.hex < n
        ktmp.hex
      else
        ktmp.hex%n
      end
    end
  end

  def srp_compute_v(x)
    power_modulo(@g, x, @N)
  end

  def srp_compute_A(a)
    power_modulo(@g, a, @N)
  end

  def srp_compute_B(b,v)
    tmp = power_modulo(@g, b, @N)
    (tmp+v*@k)%@N
  end

  # S = (B - kg^x) ^ (a + ux) (mod N)
  def srp_compute_client_S (bb, x, u, a,k)
    bx = power_modulo(@g,x,@N)
    btmp = bb+@N*k-bx*k%@N
    power_modulo(btmp,(x*u+a),@N)
  end

  def srp_compute_server_S (aa, v, u, b)
    xtmp = power_modulo(v,u,@N)
    ytmp = xtmp*aa%@N
    power_modulo(ytmp,b,@N)
  end

  # Calculate ((b**p) % m) assuming that b and m are large integers.
  def power_modulo(b, p, m)
       z=GMP::Z.new(b)
       z.powmod(p,m).to_i
  end

  # GMPを使わない場合の関数一応残しておく
  def power_modulo_old(b, p, m)
    if p == 1
      b % m
    elsif (p & 0x1) == 0
      t = power_modulo_old(b, p >> 1, m)
      (t * t) % m
    else
      (b * power_modulo_old(b, p-1, m)) % m
    end
  end

  def srp_validate_g(g)
    if power_modulo(g, (@N-1)/2, @N)+1 ==@N
      true
    else
      raise "g is not a primitive root"
      false
    end
  end

  def srp_validate_N(n)
    if !(prime?(n))
      raise "N is not prime"
    elsif !(prime?((n-1)/2))
      raise "(N-1)2 is not prime"
    end
  end

  # ゼロをn個並べた文字列を返す
  def nzero(n)
    c =''
    n.times{|i|c+='0'}
    c
  end

  # Hexからハッシュ
  def sha1_hash_hex(h)
    Digest::SHA1.hexdigest(hex2array(h).pack('C*'))
  end

  # HexからArray
  def hex2array(h)
    a = []
    h.length.times{ |i| a << h[i,2].hex if (i%2==0)}
    a
  end

  # ArrayからHex
  def array2hex(h)
    a = ""
    h.each{ |i|
      if i>15
        a << i.to_s(16)
      else
        a << "0"+(i.to_s(16))
      end
    }
    a
  end

# Miller-Rabin Test  (Prime Test)
# See, http://www.cs.albany.edu/~berg/csi445/Assignments/pa4.html
  def bitarray(n)
    b=Array::new
    i=0
    v=n
    while v > 0
      b[i] = (0x1 & v)
      v = v/2
      i = i + 1
    end
    return b
  end
  def miller_rabin(n,s)
    b=bitarray(n-1)
    i=b.size
    j =1
    while j <= s
      a = 1 + (rand(n-2).to_i)
      if witness(a,n,i,b) == true
        return false
      end
      j+=1
    end
    return true
  end
  def witness(a,n,i,b)
    d=1
    x=0
    while i > 0
      x = d
      d = (d**2) % n
      if ( (d == 1) && (x != 1) && (x != (n-1)) )
        return true
      end
      if ( b[i-1] == 1 )
        d = (d * a ) % n
      end
      i -= 1
    end
    if ( d != 1)
      return true
    end
    return false
  end
  def prime?(a)
    miller_rabin(a,10)
  end

end

class Array
  def ^(other)
    des_a=[]
    ln=other.size
    self.each_index do |i|
      des_a[i]=self[i]^other[(i)%ln]
    end
    des_a
  end
end
