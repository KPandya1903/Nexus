import { GitHubRepo } from "@/types";

const GITHUB_API_URL = "https://api.github.com";

interface GitHubApiResponse {
  stargazers_count: number;
  forks_count: number;
  language: string;
}

export async function fetchGitHubRepo(owner: string, repo: string): Promise<GitHubRepo | null> {
  try {
    const response = await fetch(`${GITHUB_API_URL}/repos/${owner}/${repo}`, {
      headers: {
        Accept: "application/vnd.github.v3+json",
      },
      next: { revalidate: 3600 }, // Cache for 1 hour
    });

    if (!response.ok) {
      console.error(`Failed to fetch GitHub repo: ${owner}/${repo}`);
      return null;
    }

    const data: GitHubApiResponse = await response.json();

    return {
      name: repo,
      stars: data.stargazers_count,
      forks: data.forks_count,
      language: data.language,
    };
  } catch (error) {
    console.error(`Error fetching GitHub repo ${owner}/${repo}:`, error);
    return null;
  }
}

export async function fetchMultipleRepos(repos: string[]): Promise<(GitHubRepo | null)[]> {
  const promises = repos.map((repoPath) => {
    const [owner, repo] = repoPath.split("/");
    return fetchGitHubRepo(owner, repo);
  });

  return Promise.all(promises);
}
