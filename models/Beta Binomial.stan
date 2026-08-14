functions{
  real frank_lpdf(matrix p_i, vector alpha, vector beta, real omega){
    real f1;
    real f2;
    int r;
    vector[rows(p_i)] f3;
    vector[rows(p_i)] f4;
    
    r = rows(p_i);
    
    f1 = beta_lpdf(col(p_i, 1)| alpha[1], beta[1]);
    f2 = beta_lpdf(col(p_i, 2)| alpha[2], beta[2]);
    for (i in 1:r){
      f3[i] = (omega*(1 - exp(-omega))*exp(-omega*(beta_cdf(p_i[i,1], alpha[1], beta[1]) + beta_cdf(p_i[i,2], alpha[2], beta[2]))));
      f4[i] = ((1 - exp(-omega)) - (1 - exp(-omega*beta_cdf(p_i[i,1], alpha[1], beta[1])))*(1 - exp(-omega*beta_cdf(p_i[i,2], alpha[2], beta[2]))));
    }
    return (f1 + f2 + sum(log((f3)./((f4).*(f4))))); 
  }
}
data{
  int N;
  int Nt;
  int Ns;

  int TP[N];
  int Dis[N];
  int TN[N];
  int NDis[N];
  int Study[N];
  int Test[N];

}
parameters{
  vector<lower=0, upper=1>[2] MU[Nt]; //mu_jk
  vector<lower=0, upper=1>[2] delta[Nt]; //delta_jk
  vector<lower=0, upper=1>[2] theta; //theta_j
  matrix<lower=0, upper=1>[Ns, 2] p_i[Nt]; //pi_ijk
  vector[Nt] omega; //omega_k
}

transformed parameters{
  vector<lower=0>[2] alpha[Nt]; //alpha_jk
  vector<lower=0>[2] beta[Nt]; //beta_jk
  
  vector[2] RR[Nt]; //RR_jk
  vector[2] OR[Nt]; //OR_jk
  vector[Nt] S; //S_k
  matrix[Nt, Nt] A;
  matrix[Nt, Nt] B;
  matrix[Nt, Nt] C;
  matrix[Nt,Nt] RD[2];
  vector[Nt] DOR;
  
  for(k in 1:Nt){
    alpha[k] = (MU[k]).*((1 - (theta).*(delta[k]))./((theta).*(delta[k])));
    beta[k] = (1 - MU[k]).*((1 - (theta).*(delta[k]))./((theta).*(delta[k])));
  }
  
  for (l in 1:Nt){
	DOR[l] = (MU[l, 1]*MU[l, 2])/((1 - MU[l, 1])*(1 - MU[l, 2]));
    for(m in 1:Nt){
      A[l, m] = (((MU[l][1] > MU[m][1]) && (MU[l][2] > MU[m][2])) ? 1 : 0);
      B[l, m] = (((MU[l][1] < MU[m][1]) && (MU[l][2] < MU[m][2])) ? 1 : 0);
      C[l, m] = (((MU[l][1] == MU[m][1]) && (MU[l][2] == MU[m][2])) ? 1 : 0);
    }
    
    S[l] = (2*sum(row(A, l)) + sum(row(C, l)))/(2*sum(row(B, l)) + sum(row(C, l)));
  }
  
  for (k in 1:Nt){
    RR[k] = MU[k]./MU[1];
    OR[k] = (MU[k]./(1 - MU[k]))./(MU[1]./(1 - MU[1]));
    }
  
  
  for (j in 1:2){
    for (k in 1:Nt){
      for (l in 1:Nt){
        RD[j][k,l] = MU[k, j]/MU[l, j];
      }
    }
  }
  
  
}
model{
  //Priors
  for (k in 1:Nt){
    MU[k] ~ uniform(0, 1);
    delta[k] ~ uniform(0, 1);
  }
  theta ~ uniform(0, 1);
  omega ~ normal(0, 1);
  
  for (k in 1:Nt)
    p_i[k] ~ frank(alpha[k], beta[k], omega[k]);
  
  for (n in 1:N){
    TP[n] ~ binomial(Dis[n], p_i[Test[n]][Study[n], 1]);
    TN[n] ~ binomial(NDis[n], p_i[Test[n]][Study[n], 2]);
  }
}
generated quantities{
  vector[2*N] loglik;
  
  for (n in 1:N)
    loglik[n] = binomial_lpmf(TN[n]| NDis[n], p_i[Test[n]][Study[n], 1]);
  
  for (n in (N+1):(2*N))
    loglik[n] = binomial_lpmf(TN[n-N]| NDis[n-N], p_i[Test[n-N]][Study[n-N], 2]);
}
